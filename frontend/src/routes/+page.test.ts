import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/svelte';
import Page from './+page.svelte';

// API モック
vi.mock('$lib/api', () => ({
  shuffleService: {
    createShuffle: vi.fn()
  }
}));

import { shuffleService } from '$lib/api';

describe('+page.svelte', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('初期表示', () => {
    it('ヘッダー「Shuffle Lunch」が表示される', () => {
      render(Page);
      expect(screen.getByRole('heading', { level: 1 })).toHaveTextContent('Shuffle Lunch');
    });

    it('参加者リストのラベルが表示される', () => {
      render(Page);
      expect(screen.getByText('参加者リスト（1行に1名）')).toBeInTheDocument();
    });

    it('店舗リストのラベルが表示される', () => {
      render(Page);
      expect(screen.getByText('お店リスト（1行に1店舗）')).toBeInTheDocument();
    });

    it('シャッフルボタンが表示される', () => {
      render(Page);
      expect(screen.getByRole('button', { name: 'シャッフルする！' })).toBeInTheDocument();
    });

    it('プレースホルダーメッセージが表示される', () => {
      render(Page);
      expect(screen.getByText('メンバーを入力してシャッフルしてください')).toBeInTheDocument();
    });
  });

  describe('アコーディオン', () => {
    it('初期状態では店舗リストのテキストエリアは非表示', () => {
      render(Page);
      const textareas = screen.getAllByRole('textbox');
      // 参加者リストのテキストエリアのみ表示
      expect(textareas).toHaveLength(1);
    });

    it('アコーディオンをクリックすると店舗リストが表示される', async () => {
      render(Page);

      const accordionButton = screen.getByRole('button', { name: /お店リスト/ });
      await fireEvent.click(accordionButton);

      const textareas = screen.getAllByRole('textbox');
      expect(textareas).toHaveLength(2);
    });

    it('再度クリックすると店舗リストが非表示になる', async () => {
      render(Page);

      const accordionButton = screen.getByRole('button', { name: /お店リスト/ });
      await fireEvent.click(accordionButton);
      await fireEvent.click(accordionButton);

      const textareas = screen.getAllByRole('textbox');
      expect(textareas).toHaveLength(1);
    });
  });

  describe('バリデーション', () => {
    it('参加者が3名未満でエラーメッセージが表示される', async () => {
      render(Page);

      const textarea = screen.getByPlaceholderText('名前を入力...');
      await fireEvent.input(textarea, { target: { value: '佐藤\n鈴木' } });

      const shuffleButton = screen.getByRole('button', { name: 'シャッフルする！' });
      await fireEvent.click(shuffleButton);

      expect(screen.getByText('参加者は3名以上で入力してください')).toBeInTheDocument();
    });

    it('参加者が空でエラーメッセージが表示される', async () => {
      render(Page);

      const shuffleButton = screen.getByRole('button', { name: 'シャッフルする！' });
      await fireEvent.click(shuffleButton);

      expect(screen.getByText('参加者は3名以上で入力してください')).toBeInTheDocument();
    });

    it('店舗リストが空でエラーメッセージが表示される', async () => {
      render(Page);

      // 参加者を入力
      const textarea = screen.getByPlaceholderText('名前を入力...');
      await fireEvent.input(textarea, { target: { value: '佐藤\n鈴木\n田中' } });

      // アコーディオンを開いて店舗リストをクリア
      const accordionButton = screen.getByRole('button', { name: /お店リスト/ });
      await fireEvent.click(accordionButton);

      const restaurantTextarea = screen.getByPlaceholderText('店舗名を改行区切りで入力');
      await fireEvent.input(restaurantTextarea, { target: { value: '' } });

      // シャッフル実行
      const shuffleButton = screen.getByRole('button', { name: 'シャッフルする！' });
      await fireEvent.click(shuffleButton);

      expect(screen.getByText('店舗を1つ以上入力してください')).toBeInTheDocument();
    });
  });

  describe('シャッフル実行', () => {
    it('シャッフル成功時にグループが表示される', async () => {
      const mockResponse = {
        groups: [
          { id: 1, groupName: 'Team A', members: ['佐藤', '鈴木', '田中'], restaurant: '中華料理店' }
        ]
      };
      vi.mocked(shuffleService.createShuffle).mockResolvedValue(mockResponse);

      render(Page);

      const textarea = screen.getByPlaceholderText('名前を入力...');
      await fireEvent.input(textarea, { target: { value: '佐藤\n鈴木\n田中' } });

      const shuffleButton = screen.getByRole('button', { name: 'シャッフルする！' });
      await fireEvent.click(shuffleButton);

      // APIが呼ばれるのを待つ
      await vi.waitFor(() => {
        expect(screen.getByText('Team A')).toBeInTheDocument();
      });

      expect(screen.getByText('@ 中華料理店')).toBeInTheDocument();
    });

    it('シャッフル成功時にコピーボタンが表示される', async () => {
      const mockResponse = {
        groups: [
          { id: 1, groupName: 'Team A', members: ['佐藤', '鈴木', '田中'], restaurant: '中華料理店' }
        ]
      };
      vi.mocked(shuffleService.createShuffle).mockResolvedValue(mockResponse);

      render(Page);

      const textarea = screen.getByPlaceholderText('名前を入力...');
      await fireEvent.input(textarea, { target: { value: '佐藤\n鈴木\n田中' } });

      const shuffleButton = screen.getByRole('button', { name: 'シャッフルする！' });
      await fireEvent.click(shuffleButton);

      await vi.waitFor(() => {
        expect(screen.getByRole('button', { name: '結果をテキストでコピー' })).toBeInTheDocument();
      });
    });

    it('API エラー時にエラーメッセージが表示される', async () => {
      vi.mocked(shuffleService.createShuffle).mockRejectedValue(new Error('API Error'));

      render(Page);

      const textarea = screen.getByPlaceholderText('名前を入力...');
      await fireEvent.input(textarea, { target: { value: '佐藤\n鈴木\n田中' } });

      const shuffleButton = screen.getByRole('button', { name: 'シャッフルする！' });
      await fireEvent.click(shuffleButton);

      await vi.waitFor(() => {
        expect(screen.getByText('シャッフル処理でエラーが発生しました')).toBeInTheDocument();
      });
    });
  });

  describe('コピー機能', () => {
    it('コピーボタンをクリックするとクリップボードにコピーされる', async () => {
      const mockResponse = {
        groups: [
          { id: 1, groupName: 'Team A', members: ['佐藤', '鈴木'], restaurant: '中華料理店' },
          { id: 2, groupName: 'Team B', members: ['田中', '高橋'], restaurant: 'イタリアン' }
        ]
      };
      vi.mocked(shuffleService.createShuffle).mockResolvedValue(mockResponse);

      // クリップボードAPIのモック
      const writeTextMock = vi.fn();
      Object.assign(navigator, {
        clipboard: { writeText: writeTextMock }
      });

      render(Page);

      const textarea = screen.getByPlaceholderText('名前を入力...');
      await fireEvent.input(textarea, { target: { value: '佐藤\n鈴木\n田中\n高橋' } });

      const shuffleButton = screen.getByRole('button', { name: 'シャッフルする！' });
      await fireEvent.click(shuffleButton);

      await vi.waitFor(() => {
        expect(screen.getByRole('button', { name: '結果をテキストでコピー' })).toBeInTheDocument();
      });

      const copyButton = screen.getByRole('button', { name: '結果をテキストでコピー' });
      await fireEvent.click(copyButton);

      expect(writeTextMock).toHaveBeenCalledWith(
        '[Team A] 佐藤, 鈴木 @ 中華料理店\n[Team B] 田中, 高橋 @ イタリアン'
      );
    });
  });
});
