import axios from 'axios';

const API_BASE = 'http://localhost:3000';

export interface ShuffleRequest {
  participants: string[];
  restaurants: string[];
}

export interface ShuffleGroup {
  id: number;
  members: string[];
  restaurant: string;
}

export interface ShuffleResponse {
  groups: ShuffleGroup[];
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