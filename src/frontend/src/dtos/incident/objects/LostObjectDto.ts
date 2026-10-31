export interface LostObjectDto {
  title: string;
  description: string;
  reportedAt: string;
  status: LostObjectStatus;
  photoUrl?: string;
  structureId: string;
}
