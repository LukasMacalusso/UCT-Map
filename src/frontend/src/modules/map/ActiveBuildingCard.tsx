import { useState } from 'react';
import { createPortal } from 'react-dom';
import type { BuildingLocationDto } from '../../dtos/campus/BuildingLocationDto';
import { useBuildingRooms } from '../../hooks/useCampus';
import { ModalOverlay } from '../../components/layout/ModalOverlay';
import { BuildingDetailCard } from './BuildingDetailCard';
import { BuildingMoreInfoCard } from './BuildingMoreInfoCard';
import type { RoomData } from '../../interfaces/RoomData';

interface ActiveBuildingCardProps {
  building: BuildingLocationDto | null;
  onClose: () => void;
}

export const ActiveBuildingCard = ({ building, onClose }: ActiveBuildingCardProps) => {
  const [moreInfoBuildingId, setMoreInfoBuildingId] = useState<string | null>(null);
  const { data: rooms, isLoading, isError } = useBuildingRooms(building?.id || '');

  if (!building) return null;

  const isMoreInfoOpen = moreInfoBuildingId === building.id;

  // Map RoomDto to RoomData expected by BuildingDetailCard
  const mappedRooms: RoomData[] = rooms?.map(r => ({
    title: r.name,
    type: "Sala Regular",
    capacity: `Piso ${r.floor}${r.number ? ` - Sala ${r.number}` : ''}`,
  })) || [];

  const schedule = isLoading ? "Cargando..." : isError ? "Error al cargar salas" : "08:00 - 22:00";
  const floors = building.metadata?.floorsCount
    ? `${building.metadata.floorsCount} ${building.metadata.floorsCount === 1 ? 'piso' : 'pisos'}`
    : '';

  return (
    <div className="w-full">
      <BuildingDetailCard
        title={building.name}
        subtitle="UCT Campus"
        floors={floors}
        withUctBorder={false}
        schedule={schedule}
        rooms={mappedRooms}
        onClose={onClose}
        onInfo={() => setMoreInfoBuildingId(building.id)}
      />

      {createPortal(
        <ModalOverlay isOpen={isMoreInfoOpen} onClose={() => setMoreInfoBuildingId(null)}>
          <BuildingMoreInfoCard
            title={building.name}
            subtitle="UCT Campus"
            floors={floors}
            description={`El ${building.name} forma parte del campus universitario. Aquí puedes revisar información ampliada sobre sus instalaciones, salas y servicios.`}
            schedule={schedule}
            rooms={mappedRooms}
            coordinates={building.location}
            onClose={() => setMoreInfoBuildingId(null)}
          />
        </ModalOverlay>,
        document.body
      )}
    </div>
  );
};
