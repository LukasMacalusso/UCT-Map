import { useState, useEffect, useCallback } from 'react';
import { Select } from '../components/ui/Select';
import { SearchInput } from '../components/ui/SearchInput';
import { Button } from '../components/ui/Button';
import { LoadingSpinner } from '../components/ui/LoadingSpinner';
import { EmptyState } from '../components/ui/EmptyState';
import { Pagination } from '../components/ui/Pagination';
import { UserManagementCard } from '../modules/admin/UserManagementCard';
import { userManagementService } from '../services/userManagementService';
import { useAuthState } from '../states/authState';
import { Role } from '../constants/role';
import type { UserIdentity } from '../interfaces/identities/UserIdentity';

import SearchIcon from '../assets/svg/icons/icon_search.svg?react';
import CategoryIcon from '../assets/svg/icons/icon_category_cube.svg?react';
import RefreshIcon from '../assets/svg/icons/icon_repeat.svg?react';

const PAGE_SIZE = 20;

const labelOf = (user: UserIdentity) => `${user.name} (${user.email})`;

export const AdministrationView = () => {
  const currentUserId = useAuthState((state) => state.user?.id);

  const [users, setUsers] = useState<UserIdentity[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [searchQuery, setSearchQuery] = useState('');
  const [selectedRole, setSelectedRole] = useState('todos');
  const [currentPage, setCurrentPage] = useState(1);

  const roleOptions = [
    { value: 'todos', label: 'Todos los roles' },
    { value: Role.Student, label: 'Estudiante' },
    { value: Role.Teacher, label: 'Profesor' },
    { value: Role.Admin, label: 'Administrador' },
    { value: Role.ComplaintsOfficer, label: 'Encargado de Incidentes' },
    { value: Role.ObjectsOfficer, label: 'Encargado de Objetos' },
  ];

  const loadUsers = useCallback(async () => {
    setError(null);
    try {
      setUsers(await userManagementService.getAllUsers());
    } catch {
      setError('No se pudieron cargar los usuarios. Intenta nuevamente.');
    }
  }, []);

  useEffect(() => {
    setIsLoading(true);
    loadUsers().finally(() => setIsLoading(false));
  }, [loadUsers]);

  const handleRefresh = async () => {
    setIsRefreshing(true);
    await loadUsers();
    setIsRefreshing(false);
  };

  const handleToggleSuspension = async (userId: string, isSuspended: boolean) => {
    setError(null);
    setUsers((prev) => prev.map((u) => (u.id === userId ? { ...u, isSuspended } : u)));
    try {
      if (isSuspended) await userManagementService.suspendUser(userId);
      else await userManagementService.reactivateUser(userId);
    } catch {
      setUsers((prev) => prev.map((u) => (u.id === userId ? { ...u, isSuspended: !isSuspended } : u)));
      setError('No se pudo cambiar el estado de la cuenta.');
    }
  };

  const handleRoleChange = async (userId: string, newRole: Role) => {
    const previousRole = users.find((u) => u.id === userId)?.role;
    if (!previousRole || previousRole === newRole) return;

    setError(null);
    setUsers((prev) => prev.map((u) => (u.id === userId ? { ...u, role: newRole } : u)));
    try {
      await userManagementService.updateUserRole(userId, newRole);
    } catch {
      setUsers((prev) => prev.map((u) => (u.id === userId ? { ...u, role: previousRole } : u)));
      setError('No se pudo cambiar el rol del usuario.');
    }
  };

  const query = searchQuery.trim().toLowerCase();
  const filteredUsers = users.filter((user) => {
    const matchesRole = selectedRole === 'todos' || user.role === selectedRole;
    const matchesSearch = !query || labelOf(user).toLowerCase().includes(query);
    return matchesRole && matchesSearch;
  });

  const totalPages = Math.max(1, Math.ceil(filteredUsers.length / PAGE_SIZE));
  const activePage = Math.min(currentPage, totalPages);
  const paginatedUsers = filteredUsers.slice(
    (activePage - 1) * PAGE_SIZE,
    activePage * PAGE_SIZE
  );

  const handleSearchChange = (value: string) => {
    setSearchQuery(value);
    setCurrentPage(1);
  };

  const handleRoleFilterChange = (value: string) => {
    setSelectedRole(value);
    setCurrentPage(1);
  };

  return (
    <div className="p-6 min-h-screen bg-page-dark flex flex-col gap-6">

      {/* Filter Bar */}
      <div className="bg-page-dark py-2 px-4 flex flex-col gap-4">
        <div className="flex flex-wrap items-end justify-end gap-4">

          {/* User Search */}
          <div className="w-80">
            <SearchInput
              label="Buscar Usuario"
              placeholder="Buscar por nombre o correo..."
              value={searchQuery}
              onChange={handleSearchChange}
              icon={<SearchIcon className="w-5 h-5 text-gray-500" />}
              showSuggestions={false}
            />
          </div>

          {/* Role Filter */}
          <div className="w-72">
            <Select
              label="Filtrar por Rol"
              options={roleOptions}
              value={selectedRole}
              onChange={handleRoleFilterChange}
              icon={<CategoryIcon className="w-5 h-5 text-gray-700" />}
            />
          </div>

          <Button
            variant="solid"
            color="blue"
            size="md"
            className="!w-auto flex items-center gap-2"
            onClick={handleRefresh}
            disabled={isRefreshing || isLoading}
          >
            <RefreshIcon className={`w-4 h-4 ${isRefreshing ? 'animate-spin' : ''}`} />
            Actualizar
          </Button>

        </div>
      </div>

      {/* Results Area */}
      <div className="flex-1 flex flex-col gap-4 max-w-5xl w-full mx-auto">

        {error && (
          <div className="text-red-50 text-sm font-medium bg-red-500/90 p-3 rounded-2xl">
            {error}
          </div>
        )}

        {isLoading ? (
          <LoadingSpinner size="lg" text="Cargando usuarios..." className="mt-16" />
        ) : filteredUsers.length === 0 ? (
          <EmptyState message="No se encontraron usuarios" />
        ) : (
          <div className="flex items-start gap-6">
            <div className="flex-1 flex flex-col gap-4 min-w-0">
              {paginatedUsers.map((user) => (
                <UserManagementCard
                  key={user.id}
                  id={user.id}
                  name={user.name}
                  email={user.email}
                  avatarSrc={user.avatar}
                  role={user.role}
                  isSuspended={user.isSuspended}
                  canToggleSuspension={user.id !== currentUserId}
                  onRoleChange={handleRoleChange}
                  onToggleSuspension={handleToggleSuspension}
                />
              ))}
            </div>

            <Pagination
              currentPage={activePage}
              totalPages={totalPages}
              onPageChange={setCurrentPage}
              className="sticky top-6"
            />
          </div>
        )}

      </div>

    </div>
  );
};
