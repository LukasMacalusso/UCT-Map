import { useState } from 'react';
import { createPortal } from 'react-dom';
import { Panel } from '../../components/layout/Panel';
import { Input } from '../../components/ui/Input';
import { Button } from '../../components/ui/Button';
import { BuildingDetailCard } from '../map/BuildingDetailCard';

interface BuildingFormModalProps {
  onClose: () => void;
}

export const BuildingFormModal = ({ onClose }: BuildingFormModalProps) => {
  const [formData, setFormData] = useState({
    title: 'NUEVO EDIFICIO',
    subtitle: 'Campus Ejemplo',
    floors: '2 Pisos',
    schedule: '08:00 - 18:00',
    services: 'WIFI, BAÑOS'
  });

  const handleChange = (field: string, value: string) => {
    setFormData(prev => ({ ...prev, [field]: value }));
  };

  const modalContent = (
    <div className="fixed inset-0 z-[9999] flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
      <Panel outerClassName="rounded-3xl shadow-2xl max-w-5xl w-full bg-white" innerClassName="flex flex-row p-0 overflow-hidden">

        {/* Form side */}
        <div className="flex-1 p-8 flex flex-col gap-5 border-r border-gray-200">
          <h2 className="text-2xl font-black text-gray-800 uppercase tracking-tight mb-2">Editar Edificio</h2>

          <Input
            label="Título del Edificio"
            labelColor="text-gray-700"
            value={formData.title}
            onChange={(e) => handleChange('title', e.target.value)}
          />
          <Input
            label="Subtítulo / Campus"
            labelColor="text-gray-700"
            value={formData.subtitle}
            onChange={(e) => handleChange('subtitle', e.target.value)}
          />
          <Input
            label="Pisos"
            labelColor="text-gray-700"
            value={formData.floors}
            onChange={(e) => handleChange('floors', e.target.value)}
          />
          <Input
            label="Horario"
            labelColor="text-gray-700"
            value={formData.schedule}
            onChange={(e) => handleChange('schedule', e.target.value)}
          />
          <Input
            label="Servicios (Separados por coma)"
            labelColor="text-gray-700"
            value={formData.services}
            onChange={(e) => handleChange('services', e.target.value)}
          />

          <div className="flex gap-4 mt-4">
            <Button color="blue" className="flex-1" onClick={onClose}>Guardar</Button>
            <Button variant="outline" className="flex-1" onClick={onClose}>Cancelar</Button>
          </div>
        </div>

        {/* Preview side */}
        <div className="flex-1 p-8 bg-gray-50 flex flex-col items-center justify-center">
          <h3 className="text-sm font-bold text-gray-400 uppercase tracking-widest mb-6">Previsualización</h3>
          <BuildingDetailCard
            title={formData.title}
            subtitle={formData.subtitle}
            floors={formData.floors}
            schedule={formData.schedule}
            services={formData.services.split(',').map(s => s.trim()).filter(Boolean)}
            onClose={onClose}
          />
        </div>

      </Panel>
    </div>
  );

  return createPortal(modalContent, document.body);
};
