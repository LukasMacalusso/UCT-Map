import { describe, it, expect, vi } from 'vitest';
import { screen, fireEvent } from '@testing-library/react';
import { ContactCard } from './ContactCard';
import { ContactProfilePanel } from './ContactProfilePanel';
import { renderWithQueryClient } from '../../test/renderWithQueryClient';

describe('Contacts modules', () => {
  it('renders ContactCard and triggers onInfoClick', () => {
    const onInfoClick = vi.fn();
    renderWithQueryClient(
      <ContactCard
        name="Prof. Valenzuela"
        department="Informática"
        campus="Campus San Juan Pablo II"
        office="Oficina 201"
        email="prof@uct.cl"
        onInfoClick={onInfoClick}
      />,
    );

    expect(screen.getByText('Prof. Valenzuela')).toBeInTheDocument();
    expect(screen.getByText('Informática')).toBeInTheDocument();
    expect(screen.getByText('Campus San Juan Pablo II')).toBeInTheDocument();

    const infoBtn = screen.getByRole('button', { name: /info/i });
    fireEvent.click(infoBtn);
    expect(onInfoClick).toHaveBeenCalled();
  });

  it('renders ContactProfilePanel and books an available slot', () => {
    const onBookSlot = vi.fn();
    const onClose = vi.fn();

    renderWithQueryClient(
      <ContactProfilePanel
        name="Prof. Valenzuela"
        role="Docente"
        department="Informática"
        email="prof@uct.cl"
        officeHours={[
          {
            id: 'oh1',
            dayOfWeek: 'Tuesday',
            startTime: '09:00:00',
            endTime: '11:00:00',
            structureRefId: 'st-1',
          },
        ]}
        meetings={[]}
        onBookSlot={onBookSlot}
        onClose={onClose}
      />,
    );

    expect(screen.getByText('Prof. Valenzuela')).toBeInTheDocument();
    expect(screen.getByText('Docente')).toBeInTheDocument();
  });
});
