export interface RoomDto {
  id: string;
  buildingId: string;
  categoryId: string;
  name: string;
  floor: number;
  number?: string;
}

export interface CreateRoomDto {
  buildingId: string;
  categoryId: string;
  name: string;
  floor: number;
}

export interface UpdateRoomDto {
  buildingId: string;
  categoryId: string;
  name: string;
  floor: number;
}
