import type { BuildingLocationDto } from '../../dtos/campus/BuildingLocationDto';
import { useBuildingRooms } from '../../hooks/useCampus';
import { BuildingDetailCard } from './BuildingDetailCard';
import type { RoomData } from '../../interfaces/RoomData';

interface ActiveBuildingCardProps {
  building: BuildingLocationDto | null;
  onClose: () => void;
}

export const ActiveBuildingCard = ({ building, onClose }: ActiveBuildingCardProps) => {
  const { data: rooms, isLoading, isError } = useBuildingRooms(building?.id || '');

  if (!building) return null;

  // Map RoomDto to RoomData expected by BuildingDetailCard
  const mappedRooms: RoomData[] = rooms?.map(r => ({
    title: r.name,
    type: "Sala Regular",
    capacity: `Piso ${r.floor}${r.number ? ` - Sala ${r.number}` : ''}`,
  })) || [];

  return (
    <div className="w-full h-full">
      <BuildingDetailCard
        title={building.name}
        subtitle="UCT Campus"
        schedule={isLoading ? "Cargando..." : isError ? "Error al cargar salas" : "08:00 - 22:00"}
        rooms={mappedRooms}
        onClose={onClose}
      />
    </div>
  );
};
