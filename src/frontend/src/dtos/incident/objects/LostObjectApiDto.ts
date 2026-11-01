export interface LostObjectApiDto {
  id?: string;
  userRefId?: string;
  title: string;
  description: string;
  date: string;
  status: string;
  photoUrl: string | null;
  structureId: string;
}
