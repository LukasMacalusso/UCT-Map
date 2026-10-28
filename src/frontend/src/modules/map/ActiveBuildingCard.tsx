import type { BuildingLocationDto } from '../../dtos/campus/BuildingLocationDto';
import { useBuildingRooms } from '../../hooks/useCampus';
import { BuildingDetailCard } from './BuildingDetailCard';
import type { RoomData } from '../../interfaces/RoomData';

interface ActiveBuildingCardProps {
  building: BuildingLocationDto | null;
  onClose: () => void;
}

export const ActiveBuildingCard = ({ building, onClose }: ActiveBuildingCardProps) => {
  const { data: rooms, isLoading } = useBuildingRooms(building?.id || '');

  if (!building) return null;

  // Map RoomDto to RoomData expected by BuildingDetailCard
  const mappedRooms: RoomData[] = rooms?.map(r => ({
    name: r.name,
    floor: r.floor,
    code: r.number,
  })) || [];

  const schedule = building.metadata?.schedule || "Sin horario registrado";
  const floors = building.metadata?.floorsCount
    ? `${building.metadata.floorsCount} ${building.metadata.floorsCount === 1 ? 'piso' : 'pisos'}`
    : '';

  return (
    <div className="w-full h-full">
      <BuildingDetailCard
        title={building.name}
        subtitle="UCT Campus"
        floors={floors}
        withUctBorder={false}
        schedule={schedule}
        rooms={mappedRooms}
        roomsLoading={isLoading}
        onClose={onClose}
      />
    </div>
  );
};
