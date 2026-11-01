import { useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Select } from '../components/ui/Select';
import { Button } from '../components/ui/Button';
import { EmptyState } from '../components/ui/EmptyState';
import { LoadingSpinner } from '../components/ui/LoadingSpinner';
import { Pagination } from '../components/ui/Pagination';
import { ModalOverlay } from '../components/layout/ModalOverlay';
import { IncidentCard } from '../modules/incidents/IncidentCard';
import { PublishReportCard, type PublishIncidentReportData } from '../modules/incidents/PublishReportCard';
import { useReports, useCreateReport } from '../hooks/useReports';
import { useAuthState } from '../states/authState';
import { useCampuses, useStructures } from '../hooks/useCampus';
import { useUsers } from '../hooks/useUsers';
import { ComplaintStatus } from '../constants/complaintStatus';
import {
  TicketStatus,
  TICKET_STATUS_COLORS,
  TICKET_STATUS_LABELS,
} from '../constants/ticketStatus';
import { formatRelativeTime } from '../utils/date';
import type { ReportSearchParams } from '../dtos/incident/reports/ReportSearchParams';

import BuildingIcon from '../assets/svg/icons/icon_building.svg?react';
import SortIcon from '../assets/svg/icons/icon_sort.svg?react';
import PlusIcon from '../assets/svg/icons/icon_plus.svg?react';

const PAGE_SIZE = 10;

export const IncidentsView = () => {
  const [sortOrder, setSortOrder] = useState('reciente');
  const [campusId, setCampusId] = useState('');
  const [structureId, setStructureId] = useState('');
  const [page, setPage] = useState(1);
  const [isCreateOpen, setIsCreateOpen] = useState(false);

  const { data: campuses = [] } = useCampuses();
  const { data: structures = [] } = useStructures();
  const { data: users = [] } = useUsers();
  const createReport = useCreateReport();

  const params = useMemo<ReportSearchParams>(
    () => ({
      structureRefId: structureId || undefined,
      sortBy: 'ReportedAt',
      descending: sortOrder === 'reciente',
      page,
      pageSize: PAGE_SIZE,
    }),
    [structureId, sortOrder, page],
  );

  const { data, isLoading, isError, error } = useReports(params);

  const structureNames = useMemo(
    () => new Map(structures.map((structure) => [structure.id, structure.name])),
    [structures],
  );

  const usersById = useMemo(() => new Map(users.map((user) => [user.id, user])), [users]);

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

  const navigate = useNavigate();
  const isAuthenticated = useAuthState((state) => state.isAuthenticated);

  const openCreate = () => {
    if (!isAuthenticated) {
      navigate('/login');
      return;
    }
    createReport.reset();
    setIsCreateOpen(true);
  };

  const closeCreate = () => setIsCreateOpen(false);

  const handlePublish = (report: PublishIncidentReportData) => {
    createReport.mutate(
      {
        structureRefId: report.structureId,
        ticketType: TicketStatus.Pending,
        isActive: true,
        reportedAt: new Date().toISOString(),
        complaint: {
          title: report.title,
          description: report.description,
          status: ComplaintStatus.Claim,
        },
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
      <div className="bg-page-dark py-2 px-4 flex flex-wrap items-end justify-end gap-4">
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

      <div className="flex-1 flex items-start gap-6">
        {isLoading ? (
          <div className="flex-1 flex items-center justify-center p-12">
            <LoadingSpinner size="lg" text="Cargando reportes..." />
          </div>
        ) : isError ? (
          <div className="flex-1 flex items-center justify-center p-12">
            <EmptyState message={error?.message ?? 'No se pudieron cargar los reportes.'} />
          </div>
        ) : !data || data.items.length === 0 ? (
          <div className="flex-1 flex items-center justify-center p-12">
            <EmptyState message="No hay reportes que coincidan con los filtros." />
          </div>
        ) : (
          <>
            <div className="flex-1 grid grid-cols-[repeat(auto-fill,minmax(min(100%,24rem),24rem))] justify-center content-start gap-6">
              {data.items.map((report) => {
                const reporter = usersById.get(report.userRefId);

                return (
                  <IncidentCard
                    key={report.id}
                    className="!w-full max-w-[24rem] !h-[30rem]"
                    location={
                      (report.structureRefId && structureNames.get(report.structureRefId)) ||
                      'Sin ubicación'
                    }
                    status={TICKET_STATUS_LABELS[report.ticketType] ?? 'SIN ESTADO'}
                    statusColor={TICKET_STATUS_COLORS[report.ticketType] ?? 'gray'}
                    title={report.complaintDetails?.title ?? 'Reporte sin título'}
                    reporterName={reporter?.name ?? 'Usuario'}
                    reporterAvatar={reporter?.avatar}
                    reportTime={formatRelativeTime(report.reportedAt)}
                    description={report.complaintDetails?.description ?? 'Sin descripción'}
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
        <PublishReportCard
          isSubmitting={createReport.isPending}
          error={createReport.error?.message ?? null}
          onPublish={handlePublish}
          onDiscard={closeCreate}
        />
      </ModalOverlay>
    </div>
  );
};
