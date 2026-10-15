import { render, screen } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import { UserProfilePanel } from './UserProfilePanel';
import { Role } from '../../constants/role';

const baseProps = {
  name: 'Ana Torres',
  email: 'ana@uct.cl',
  role: Role.Student,
};

describe('UserProfilePanel', () => {
  it('muestra únicamente el LoadingSpinner mientras carga', () => {
    render(<UserProfilePanel {...baseProps} isLoading />);

    expect(screen.getByText('Cargando perfil...')).toBeInTheDocument();
    expect(screen.queryByText('Ana Torres')).not.toBeInTheDocument();
    expect(screen.queryByText('ana@uct.cl')).not.toBeInTheDocument();
    expect(screen.queryByText('Información de Cuenta')).not.toBeInTheDocument();
    expect(screen.queryByText('CERRAR SESIÓN')).not.toBeInTheDocument();
  });

  it('muestra la información del usuario cuando ya terminó de cargar', () => {
    render(<UserProfilePanel {...baseProps} />);

    expect(screen.getByText('Ana Torres')).toBeInTheDocument();
    expect(screen.getByText('ana@uct.cl')).toBeInTheDocument();
    expect(screen.getByText('Información de Cuenta')).toBeInTheDocument();
    expect(screen.queryByText('Cargando perfil...')).not.toBeInTheDocument();
  });

  it('muestra "Tus Contribuciones" por defecto (perfil propio)', () => {
    render(<UserProfilePanel {...baseProps} />);
    expect(screen.getByText('Tus Contribuciones')).toBeInTheDocument();
  });

  it('muestra "Contribuciones" cuando el perfil no es propio', () => {
    render(<UserProfilePanel {...baseProps} isOwnProfile={false} />);
    expect(screen.getByText('Contribuciones')).toBeInTheDocument();
    expect(screen.queryByText('Tus Contribuciones')).not.toBeInTheDocument();
  });

  it('no muestra "CERRAR SESIÓN" cuando no se provee onLogout', () => {
    render(<UserProfilePanel {...baseProps} />);
    expect(screen.queryByText('CERRAR SESIÓN')).not.toBeInTheDocument();
  });

  it('muestra "CERRAR SESIÓN" cuando se provee onLogout', () => {
    render(<UserProfilePanel {...baseProps} onLogout={() => {}} />);
    expect(screen.getByText('CERRAR SESIÓN')).toBeInTheDocument();
  });
});
