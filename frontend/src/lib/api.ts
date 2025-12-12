import axios from 'axios';

const API_BASE = 'http://localhost:3000';

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
}

export interface RestaurantResponse {
  restaurants: Restaurant[];
}

export const shuffleService = {
  async createShuffle(participants: string[], restaurants: string[]): Promise<ShuffleResponse> {
    const response = await axios.post(`${API_BASE}/api/shuffles`, {
      participants,
      restaurants
    });
    return response.data;
  }
};

export const restaurantService = {
  async fetchNearby(): Promise<Restaurant[]> {
    const response = await axios.get<RestaurantResponse>(`${API_BASE}/api/restaurants/nearby`);
    return response.data.restaurants;
  }
};