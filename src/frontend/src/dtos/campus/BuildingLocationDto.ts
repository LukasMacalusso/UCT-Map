import type { LocationDto } from './LocationDto';
import type { BuildingMetadataDto } from './BuildingMetadataDto';

export interface BuildingLocationDto {
  id: string;
  name: string;
  location: LocationDto;
  metadata: BuildingMetadataDto;
}
