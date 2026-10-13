import { useUiState } from '../../states/uiState';
import { useAuthState } from '../../states/authState';
import { ModalOverlay } from './ModalOverlay';
import { TimedActionCard } from '../ui/TimedActionCard';
import { UserProfilePanel } from '../../modules/global/UserProfilePanel';
import { useNavigate } from 'react-router-dom';

export const GlobalModals = () => {
  const activePanel = useUiState(state => state.activePanel);
  const closePanel = useUiState(state => state.closePanel);
  const user = useAuthState(state => state.user);
  const logout = useAuthState(state => state.logout);
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    closePanel();
    navigate('/login');
  };

  return (
    <>
      <ModalOverlay
        isOpen={activePanel === 'userProfile'}
        onClose={closePanel}
      >
        {user && (
          <UserProfilePanel
            name={user.name}
            role={user.role}
            admissionYear="2022"
            career="Ingeniería Civil en Informática"
            email={user.email}
            photoUrl={user.avatar || 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80'}
            onClose={closePanel}
            onLogout={handleLogout}
            objectReports={[
              {
                title: 'LENTES DE SOL',
                status: 'En proceso',
                statusColor: 'yellow',
                building: 'EDIFICIO A',
                code: 'OP-2026-0005',
                actions: [
                  { title: `Reportado por ${user.name}`, subtitle: 'Hace 2 días', avatarSrc: user.avatar || 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80' }
                ]
              }
            ]}
            incidentReports={[
              {
                location: 'BIBLIOTECA CENTRAL',
                status: 'RESUELTO',
                statusColor: 'green',
                title: 'Luz intermitente en sala de estudio',
                reporterName: user.name,
                reportTime: 'Hace 1 semana',
                reporterAvatar: user.avatar || 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80',
                description: 'El tubo fluorescente de la mesa 4 está parpadeando constantemente.',
                photoUrl: 'https://images.unsplash.com/photo-1497215848943-4710166a9089?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'
              }
            ]}
          />
        )}
      </ModalOverlay>

      <ModalOverlay 
        isOpen={activePanel === 'saveMapChanges'} 
        onClose={closePanel}
      >
        <TimedActionCard
          title="Confirmar Cambios"
          description="Estos cambios serán públicos y visibles para todos los estudiantes. Por favor, revisa tus modificaciones antes de continuar."
          initialDurationMs={3000}
          options={[
            {
              label: "Cancelar",
              color: "gray",
              onClick: closePanel
            },
            {
              label: "Publicar Mapa",
              color: "green",
              onClick: () => {
                console.log("Mapa guardado exitosamente");
                closePanel();
              }
            }
          ]}
        />
      </ModalOverlay>

      <ModalOverlay 
        isOpen={activePanel === 'discardMapChanges'} 
        onClose={closePanel}
      >
        <TimedActionCard
          title="Descartar Cambios"
          description="Estás a punto de descartar todas las modificaciones realizadas en esta sesión. Esta acción no se puede deshacer."
          initialDurationMs={2000}
          options={[
            {
              label: "Cancelar",
              color: "gray",
              onClick: closePanel
            },
            {
              label: "Sí, descartar",
              color: "red",
              onClick: () => {
                console.log("Cambios descartados");
                closePanel();
              }
            }
          ]}
        />
      </ModalOverlay>
    </>
  );
};
