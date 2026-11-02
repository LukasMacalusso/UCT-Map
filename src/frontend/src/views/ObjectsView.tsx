import { useEffect, useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Select } from '../components/ui/Select';
import { Button } from '../components/ui/Button';
import { SearchInput } from '../components/ui/SearchInput';
import { EmptyState } from '../components/ui/EmptyState';
import { LoadingSpinner } from '../components/ui/LoadingSpinner';
import { Pagination } from '../components/ui/Pagination';
import { ModalOverlay } from '../components/layout/ModalOverlay';
import { ObjectReportCard } from '../modules/objects/ObjectReportCard';
import {
  ReportLostObjectCard,
  type ReportLostObjectData,
} from '../modules/objects/ReportLostObjectCard';
import { useLostObjects, useCreateLostObject } from '../hooks/useLostObjects';
import { useAuthState } from '../states/authState';
import { useCampuses, useStructures } from '../hooks/useCampus';
import { useUsers } from '../hooks/useUsers';
import {
  LostObjectStatus,
  LOST_OBJECT_STATUS_COLORS,
  LOST_OBJECT_STATUS_LABELS,
} from '../constants/lostObjectsStatus';
import { formatRelativeTime } from '../utils/date';
import type { LostObjectSearchParams } from '../dtos/incident/objects/LostObjectSearchParams';

import SearchIcon from '../assets/svg/icons/icon_search.svg?react';
import BuildingIcon from '../assets/svg/icons/icon_building.svg?react';
import SortIcon from '../assets/svg/icons/icon_sort.svg?react';
import FilterIcon from '../assets/svg/icons/icon_filter.svg?react';
import PlusIcon from '../assets/svg/icons/icon_plus.svg?react';

const PAGE_SIZE = 10;

export const ObjectsView = () => {
  const [searchQuery, setSearchQuery] = useState('');
  const [debouncedQuery, setDebouncedQuery] = useState('');
  const [campusId, setCampusId] = useState('');
  const [structureId, setStructureId] = useState('');
  const [sortOrder, setSortOrder] = useState('reciente');
  const [statusFilter, setStatusFilter] = useState('');
  const [page, setPage] = useState(1);
  const [isCreateOpen, setIsCreateOpen] = useState(false);

  const { data: campuses = [] } = useCampuses();
  const { data: structures = [] } = useStructures();
  const { data: users = [] } = useUsers();
  const createLostObject = useCreateLostObject();

  useEffect(() => {
    const timeout = setTimeout(() => {
      setDebouncedQuery(searchQuery.trim());
      setPage(1);
    }, 300);

    return () => clearTimeout(timeout);
  }, [searchQuery]);

  const params = useMemo<LostObjectSearchParams>(
    () => ({
      title: debouncedQuery || undefined,
      structureId: structureId || undefined,
      status: statusFilter === '' ? undefined : (Number(statusFilter) as LostObjectStatus),
      sortBy: 'ReportedAt',
      descending: sortOrder === 'reciente',
      page,
      pageSize: PAGE_SIZE,
    }),
    [debouncedQuery, structureId, statusFilter, sortOrder, page],
  );

  const { data, isLoading, isError, error } = useLostObjects(params);

  const structureNames = useMemo(
    () => new Map(structures.map((structure) => [structure.id, structure.name])),
    [structures],
  );

  const usersById = useMemo(
    () => new Map(users.map((user) => [user.id, user])),
    [users],
  );

  const sortOptions = [
    { value: 'reciente', label: 'Reciente' },
    { value: 'antiguo', label: 'Antiguo' },
  ];

  const campusOptions = [
    { value: '', label: 'Todos los campus' },
    ...campuses.map((campus) => ({ value: campus.id, label: campus.name })),
  ];

  const structureOptions = [
    { value: '', label: 'Todos los edificios' },
    ...structures
      .filter((structure) => !campusId || structure.campusId === campusId)
      .map((structure) => ({ value: structure.id, label: structure.name })),
  ];

  const statusOptions = [
    { value: '', label: 'Todos los estados' },
    { value: String(LostObjectStatus.Pending), label: 'Pendiente' },
    { value: String(LostObjectStatus.InProcess), label: 'En proceso' },
    { value: String(LostObjectStatus.Resolved), label: 'Resuelto' },
    { value: String(LostObjectStatus.Canceled), label: 'Cancelado' },
  ];

  const handleCampusChange = (value: string) => {
    setCampusId(value);
    setStructureId('');
    setPage(1);
  };

  const handleStructureChange = (value: string) => {
    setStructureId(value);
    setPage(1);
  };

  const handleSortChange = (value: string) => {
    setSortOrder(value);
    setPage(1);
  };

  const handleStatusChange = (value: string) => {
    setStatusFilter(value);
    setPage(1);
  };

  const navigate = useNavigate();
  const isAuthenticated = useAuthState((state) => state.isAuthenticated);

  const openCreate = () => {
    if (!isAuthenticated) {
      navigate('/login');
      return;
    }
    createLostObject.reset();
    setIsCreateOpen(true);
  };

  const closeCreate = () => setIsCreateOpen(false);

  const handlePublish = (lostObject: ReportLostObjectData) => {
    createLostObject.mutate(
      {
        title: lostObject.title,
        description: lostObject.description,
        status: LostObjectStatus.Pending,
        structureId: lostObject.structureId,
      },
      {
        onSuccess: () => {
          setIsCreateOpen(false);
          setPage(1);
        },
      },
    );
  };

  return (
    <div className="p-6 min-h-screen bg-page-dark flex flex-col gap-6">
      <div className="bg-page-dark py-2 px-4 flex flex-col gap-4">
        <div className="flex flex-wrap items-end justify-end gap-4">
          <div className="w-80">
            <SearchInput
              label="Búsqueda"
              placeholder="Buscar Pérdida..."
              value={searchQuery}
              onChange={setSearchQuery}
              icon={<SearchIcon className="w-5 h-5 text-gray-500" />}
              showSuggestions={false}
            />
          </div>

          <div className="w-72">
            <Select
              label="Campus"
              options={campusOptions}
              value={campusId}
              onChange={handleCampusChange}
              icon={<BuildingIcon className="w-5 h-5 text-gray-700" />}
            />
          </div>

          <div className="w-72">
            <Select
              label="Edificio"
              options={structureOptions}
              value={structureId}
              onChange={handleStructureChange}
              icon={<BuildingIcon className="w-5 h-5 text-gray-700" />}
            />
          </div>

          <div>
            <Button
              variant="solid"
              color="blue"
              size="md"
              onClick={openCreate}
              className="font-bold tracking-wide shadow-md hover:scale-105 transition-transform whitespace-nowrap !w-auto px-6 h-[50px] flex items-center justify-center gap-2"
            >
              <PlusIcon className="w-5 h-5 stroke-[3]" /> PUBLICAR
            </Button>
          </div>
        </div>

        <div className="flex flex-wrap items-end justify-end gap-4 pt-2">
          <div className="w-52">
            <Select
              label="Ordenar por"
              options={sortOptions}
              value={sortOrder}
              onChange={handleSortChange}
              icon={<SortIcon className="w-5 h-5 text-gray-700" />}
            />
          </div>

          <div className="w-72">
            <Select
              label="Estado"
              options={statusOptions}
              value={statusFilter}
              onChange={handleStatusChange}
              icon={<FilterIcon className="w-5 h-5 text-gray-700" />}
            />
          </div>
        </div>
      </div>

      <div className="flex-1 flex items-start gap-6">
        {isLoading ? (
          <div className="flex-1 flex items-center justify-center p-12">
            <LoadingSpinner size="lg" text="Cargando objetos perdidos..." />
          </div>
        ) : isError ? (
          <div className="flex-1 flex items-center justify-center p-12">
            <EmptyState message={error?.message ?? 'No se pudieron cargar los objetos perdidos.'} />
          </div>
        ) : !data || data.items.length === 0 ? (
          <div className="flex-1 flex items-center justify-center p-12">
            <EmptyState message="No hay objetos perdidos que coincidan con los filtros." />
          </div>
        ) : (
          <>
            <div className="flex-1 grid grid-cols-[repeat(auto-fill,minmax(min(100%,38rem),38rem))] justify-center content-start gap-6">
              {data.items.map((lostObject, index) => {
                const reporter = lostObject.userRefId
                  ? usersById.get(lostObject.userRefId)
                  : undefined;

                return (
                  <ObjectReportCard
                    key={lostObject.id ?? `${lostObject.title}-${index}`}
                    className="!w-full max-w-[38rem] !h-60"
                    title={lostObject.title}
                    status={LOST_OBJECT_STATUS_LABELS[lostObject.status]}
                    statusColor={LOST_OBJECT_STATUS_COLORS[lostObject.status]}
                    photoUrl={lostObject.photoUrl}
                    building={structureNames.get(lostObject.structureId) ?? 'Sin ubicación'}
                    actions={[
                      {
                        title: reporter ? `Reportado por ${reporter.name}` : 'Reportado por Usuario',
                        subtitle: formatRelativeTime(lostObject.reportedAt),
                        avatarSrc: reporter?.avatar,
                      },
                    ]}
                  />
                );
              })}
            </div>

            <Pagination
              currentPage={data.page}
              totalPages={data.totalPages}
              onPageChange={setPage}
              className="sticky top-6"
            />
          </>
        )}
      </div>

      <ModalOverlay isOpen={isCreateOpen} onClose={closeCreate}>
        <ReportLostObjectCard
          isSubmitting={createLostObject.isPending}
          error={createLostObject.error?.message ?? null}
          onPublish={handlePublish}
          onDiscard={closeCreate}
        />
      </ModalOverlay>
    </div>
  );
};
