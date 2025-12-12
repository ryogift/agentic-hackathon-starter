import { describe, it, expect, vi, beforeEach } from "vitest";
import { render, screen, fireEvent } from "@testing-library/svelte";
import Page from "../../src/routes/+page.svelte";

// API モック
vi.mock("$lib/api", () => ({
  shuffleService: {
    createShuffle: vi.fn(),
  },
  restaurantService: {
    fetchNearby: vi.fn(),
    fetchGenres: vi.fn(),
  },
}));

import { shuffleService, restaurantService } from "$lib/api";

describe("+page.svelte", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    // デフォルトで空の店舗リストとジャンルを返す
    vi.mocked(restaurantService.fetchNearby).mockResolvedValue([]);
    vi.mocked(restaurantService.fetchGenres).mockResolvedValue([]);
  });

  describe("初期表示", () => {
    it("ヘッダー「Shuffle Lunch」が表示される", () => {
      render(Page);
      expect(screen.getByRole("heading", { level: 1 })).toHaveTextContent(
        "Shuffle Lunch",
      );
    });

    it("参加者リストのラベルが表示される", () => {
      render(Page);
      expect(screen.getByText("参加者リスト（1行に1名）")).toBeInTheDocument();
    });

    it("店舗リストのラベルが表示される", () => {
      render(Page);
      expect(screen.getByText("お店リスト")).toBeInTheDocument();
    });

    it("シャッフルボタンが表示される", () => {
      render(Page);
      expect(
        screen.getByRole("button", { name: "シャッフルする！" }),
      ).toBeInTheDocument();
    });

    it("プレースホルダーメッセージが表示される", () => {
      render(Page);
      expect(
        screen.getByText("メンバーを入力してシャッフルしてください"),
      ).toBeInTheDocument();
    });
  });

  describe("バリデーション", () => {
    it("参加者が3名未満でエラーメッセージが表示される", async () => {
      render(Page);

      const textarea = screen.getByPlaceholderText("名前を入力...");
      await fireEvent.input(textarea, { target: { value: "佐藤\n鈴木" } });

      const shuffleButton = screen.getByRole("button", {
        name: "シャッフルする！",
      });
      await fireEvent.click(shuffleButton);

      expect(
        screen.getByText("参加者は3名以上で入力してください"),
      ).toBeInTheDocument();
    });

    it("参加者が空でエラーメッセージが表示される", async () => {
      render(Page);

      // 参加者を空にする
      const textarea = screen.getByPlaceholderText("名前を入力...");
      await fireEvent.input(textarea, { target: { value: "" } });

      const shuffleButton = screen.getByRole("button", {
        name: "シャッフルする！",
      });
      await fireEvent.click(shuffleButton);

      expect(
        screen.getByText("参加者は3名以上で入力してください"),
      ).toBeInTheDocument();
    });

    it("店舗が選択されていない場合エラーメッセージが表示される", async () => {
      render(Page);

      // 参加者を入力
      const textarea = screen.getByPlaceholderText("名前を入力...");
      await fireEvent.input(textarea, {
        target: { value: "佐藤\n鈴木\n田中" },
      });

      // シャッフル実行（店舗未選択）
      const shuffleButton = screen.getByRole("button", {
        name: "シャッフルする！",
      });
      await fireEvent.click(shuffleButton);

      expect(
        screen.getByText("店舗を1つ以上選択してください"),
      ).toBeInTheDocument();
    });
  });

  describe("シャッフル実行", () => {
    it("シャッフル成功時にグループが表示される", async () => {
      const mockRestaurants = [
        {
          name: "中華料理店",
          genre: "中華",
          imageUrl: "",
          rating: null,
          url: "",
        },
      ];
      vi.mocked(restaurantService.fetchNearby).mockResolvedValue(
        mockRestaurants,
      );

      const mockResponse = {
        groups: [
          {
            id: 1,
            groupName: "Team A",
            members: ["佐藤", "鈴木", "田中"],
            restaurant: "中華料理店",
          },
        ],
      };
      vi.mocked(shuffleService.createShuffle).mockResolvedValue(mockResponse);

      render(Page);

      // 店舗データの読み込みを待つ
      await vi.waitFor(() => {
        expect(restaurantService.fetchNearby).toHaveBeenCalled();
      });

      const textarea = screen.getByPlaceholderText("名前を入力...");
      await fireEvent.input(textarea, {
        target: { value: "佐藤\n鈴木\n田中" },
      });

      const shuffleButton = screen.getByRole("button", {
        name: "シャッフルする！",
      });
      await fireEvent.click(shuffleButton);

      // APIが呼ばれるのを待つ
      await vi.waitFor(() => {
        expect(screen.getByText("Team A")).toBeInTheDocument();
      });

      expect(screen.getByText("@ 中華料理店")).toBeInTheDocument();
    });

    it("シャッフル成功時にコピーボタンが表示される", async () => {
      const mockRestaurants = [
        {
          name: "中華料理店",
          genre: "中華",
          imageUrl: "",
          rating: null,
          url: "",
        },
      ];
      vi.mocked(restaurantService.fetchNearby).mockResolvedValue(
        mockRestaurants,
      );

      const mockResponse = {
        groups: [
          {
            id: 1,
            groupName: "Team A",
            members: ["佐藤", "鈴木", "田中"],
            restaurant: "中華料理店",
          },
        ],
      };
      vi.mocked(shuffleService.createShuffle).mockResolvedValue(mockResponse);

      render(Page);

      await vi.waitFor(() => {
        expect(restaurantService.fetchNearby).toHaveBeenCalled();
      });

      const textarea = screen.getByPlaceholderText("名前を入力...");
      await fireEvent.input(textarea, {
        target: { value: "佐藤\n鈴木\n田中" },
      });

      const shuffleButton = screen.getByRole("button", {
        name: "シャッフルする！",
      });
      await fireEvent.click(shuffleButton);

      await vi.waitFor(() => {
        expect(
          screen.getByRole("button", { name: "結果をテキストでコピー" }),
        ).toBeInTheDocument();
      });
    });

    it("API エラー時にエラーメッセージが表示される", async () => {
      const mockRestaurants = [
        {
          name: "中華料理店",
          genre: "中華",
          imageUrl: "",
          rating: null,
          url: "",
        },
      ];
      vi.mocked(restaurantService.fetchNearby).mockResolvedValue(
        mockRestaurants,
      );
      vi.mocked(shuffleService.createShuffle).mockRejectedValue(
        new Error("API Error"),
      );

      render(Page);

      await vi.waitFor(() => {
        expect(restaurantService.fetchNearby).toHaveBeenCalled();
      });

      const textarea = screen.getByPlaceholderText("名前を入力...");
      await fireEvent.input(textarea, {
        target: { value: "佐藤\n鈴木\n田中" },
      });

      const shuffleButton = screen.getByRole("button", {
        name: "シャッフルする！",
      });
      await fireEvent.click(shuffleButton);

      await vi.waitFor(() => {
        expect(
          screen.getByText("シャッフル処理でエラーが発生しました"),
        ).toBeInTheDocument();
      });
    });
  });

  describe("コピー機能", () => {
    it("コピーボタンをクリックするとクリップボードにコピーされる", async () => {
      const mockRestaurants = [
        {
          name: "中華料理店",
          genre: "中華",
          imageUrl: "",
          rating: null,
          url: "",
        },
        {
          name: "イタリアン",
          genre: "洋食",
          imageUrl: "",
          rating: null,
          url: "",
        },
      ];
      vi.mocked(restaurantService.fetchNearby).mockResolvedValue(
        mockRestaurants,
      );

      const mockResponse = {
        groups: [
          {
            id: 1,
            groupName: "Team A",
            members: ["佐藤", "鈴木"],
            restaurant: "中華料理店",
          },
          {
            id: 2,
            groupName: "Team B",
            members: ["田中", "高橋"],
            restaurant: "イタリアン",
          },
        ],
      };
      vi.mocked(shuffleService.createShuffle).mockResolvedValue(mockResponse);

      // クリップボードAPIのモック
      const writeTextMock = vi.fn();
      Object.assign(navigator, {
        clipboard: { writeText: writeTextMock },
      });

      render(Page);

      await vi.waitFor(() => {
        expect(restaurantService.fetchNearby).toHaveBeenCalled();
      });

      const textarea = screen.getByPlaceholderText("名前を入力...");
      await fireEvent.input(textarea, {
        target: { value: "佐藤\n鈴木\n田中\n高橋" },
      });

      const shuffleButton = screen.getByRole("button", {
        name: "シャッフルする！",
      });
      await fireEvent.click(shuffleButton);

      await vi.waitFor(() => {
        expect(
          screen.getByRole("button", { name: "結果をテキストでコピー" }),
        ).toBeInTheDocument();
      });

      const copyButton = screen.getByRole("button", {
        name: "結果をテキストでコピー",
      });
      await fireEvent.click(copyButton);

      // URLがないので基本フォーマットでコピー
      expect(writeTextMock).toHaveBeenCalledWith(
        "[Team A] 佐藤, 鈴木 @ 中華料理店\n\n[Team B] 田中, 高橋 @ イタリアン",
      );
    });
  });
});
