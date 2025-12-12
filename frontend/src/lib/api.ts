import axios from "axios";

const API_BASE = "http://localhost:3000";

export interface ShuffleRequest {
  participants: string[];
  restaurants: string[];
}

export interface ShuffleGroup {
  id: number;
  groupName: string;
  members: string[];
  restaurant: string;
}

export interface ShuffleResponse {
  groups: ShuffleGroup[];
}

export interface Restaurant {
  name: string;
  genre: string;
  imageUrl: string;
  rating: number | null;
  url: string;
}

export interface RestaurantResponse {
  restaurants: Restaurant[];
}

export const shuffleService = {
  async createShuffle(
    participants: string[],
    restaurants: string[],
  ): Promise<ShuffleResponse> {
    const response = await axios.post(`${API_BASE}/api/shuffles`, {
      participants,
      restaurants,
    });
    return response.data;
  },
};

export const restaurantService = {
  async fetchNearby(genre?: string): Promise<Restaurant[]> {
    const params = new URLSearchParams();
    if (genre) {
      params.append("genre", genre);
    }

    const url = `${API_BASE}/api/restaurants/nearby${params.toString() ? "?" + params.toString() : ""}`;
    const response = await axios.get<RestaurantResponse>(url);
    return response.data.restaurants;
  },

  async fetchGenres(): Promise<string[]> {
    const response = await axios.get<{ genres: string[] }>(
      `${API_BASE}/api/restaurants/genres`,
    );
    return response.data.genres;
  },
};
