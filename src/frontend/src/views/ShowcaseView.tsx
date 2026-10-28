import { useState } from 'react';
import { Button } from '../components/ui/Button';
import { Input } from '../components/ui/Input';
import { Select } from '../components/ui/Select';
import { NavButton } from '../components/ui/NavButton';
import { CheckboxItem } from '../components/ui/CheckboxItem';
import { Tag } from '../components/ui/Tag';
import { Panel } from '../components/layout/Panel';
import { MapMarker } from '../components/ui/MapMarker';
import { IconText } from '../components/ui/IconText';
import { PhotoFrame } from '../components/media/PhotoFrame';
import { Avatar } from '../components/media/Avatar';
import { ImageGallery } from '../components/media/ImageGallery';
import { FileUpload } from '../components/ui/FileUpload';
import { SquareButton } from '../components/ui/SquareButton';
import { SectionButton } from '../components/ui/SectionButton';
import { UserActionInfo } from '../components/ui/UserActionInfo';
import { ContactProfilePanel } from '../modules/contacts/ContactProfilePanel';
import { ContactCard } from '../modules/contacts/ContactCard';
import { ObjectReportCard } from '../modules/objects/ObjectReportCard';
import { IncidentCard } from '../modules/incidents/IncidentCard';
import { UserManagementCard } from '../modules/admin/UserManagementCard';
import { MapEditorPanel } from '../modules/admin/MapEditorPanel';
import { TimedActionCard } from '../components/ui/TimedActionCard';
import { LoadingSpinner } from '../components/ui/LoadingSpinner';
import { UCT_LOADING_PHRASES } from '../constants/loadingPhrases';
import { RoomInfoCard } from '../modules/map/RoomInfoCard';
import { ScheduleCard } from '../modules/map/ScheduleCard';
import { MapFiltersPanel } from '../modules/map/MapFiltersPanel';
import { BuildingDetailCard } from '../modules/map/BuildingDetailCard';
import { PublishReportCard } from '../modules/objects/PublishReportCard';
import { ReportLostObjectCard } from '../modules/objects/ReportLostObjectCard';
import { UserProfilePanel } from '../modules/global/UserProfilePanel';
import { SearchInput } from '../components/ui/SearchInput';
import { NumberSelect } from '../components/ui/NumberSelect';
import type { FilterSection } from '../interfaces/FilterSection';
import { Role } from '../constants/role';

import BuildingIcon from '../assets/svg/icons/icon_building.svg?react';
import MapPinIcon from '../assets/svg/icons/icon_map_pin.svg?react';
import InfoIcon from '../assets/svg/icons/icon_info.svg?react';
import MarkerRectIcon from '../assets/svg/icons/icon_marker_rect.svg?react';
import CrossIcon from '../assets/svg/icons/icon_cross.svg?react';
import CheckIcon from '../assets/svg/icons/icon_check.svg?react';
import WarningAltIcon from '../assets/svg/icons/icon_warning_alt.svg?react';
import PhoneAltIcon from '../assets/svg/icons/icon_phone_alt.svg?react';
import MailAltIcon from '../assets/svg/icons/icon_mail_alt.svg?react';

export const ShowcaseView = () => {
  const [searchInputValue, setSearchInputValue] = useState('');
  const [filters, setFilters] = useState<FilterSection[]>([
    {
      id: 'academico',
      title: 'ACADÉMICO',
      items: [
        { id: 'edificios', label: 'Edificios', icon: <BuildingIcon className="w-6 h-6 text-gray-700" />, checked: true },
        { id: 'accesos', label: 'Accesos', icon: <BuildingIcon className="w-6 h-6 text-gray-700" />, checked: true },
        { id: 'biblioteca', label: 'Biblioteca', icon: <BuildingIcon className="w-6 h-6 text-gray-700" />, checked: false },
      ]
    },
    {
      id: 'servicios',
      title: 'SERVICIOS',
      items: [
        { id: 'primeros-auxilios', label: 'Primeros Auxilios', icon: <BuildingIcon className="w-6 h-6 text-gray-700" />, checked: true },
        { id: 'cajeros', label: 'Cajeros', icon: <BuildingIcon className="w-6 h-6 text-gray-700" />, checked: true },
      ]
    },
    {
      id: 'vida-universitaria',
      title: 'VIDA UNIVERSITARIA',
      items: [
        { id: 'casino', label: 'Casino', icon: <BuildingIcon className="w-6 h-6 text-gray-700" />, checked: true },
        { id: 'canchas', label: 'Canchas', icon: <BuildingIcon className="w-6 h-6 text-gray-700" />, checked: false },
        { id: 'kioskos', label: 'Kioskos', icon: <BuildingIcon className="w-6 h-6 text-gray-700" />, checked: false },
        { id: 'areas-verdes', label: 'Áreas Verdes', icon: <BuildingIcon className="w-6 h-6 text-gray-700" />, checked: true },
      ]
    }
  ]);

  const handleToggleFilter = (sectionId: string, itemId: string) => {
    setFilters(prev => prev.map(sec =>
      sec.id === sectionId
        ? { ...sec, items: sec.items.map(item => item.id === itemId ? { ...item, checked: !item.checked } : item) }
        : sec
    ));
  };

  return (
    <div className="min-h-screen bg-gray-50 p-12 flex flex-col gap-8 items-center font-sans">

      <MapFiltersPanel
        title="Filtros (2)"
        sections={filters}
        onToggleItem={handleToggleFilter}
      />

      <UserProfilePanel
        name="María González Pérez"
        admissionYear="2022"
        career="Ingeniería Civil en Informática"
        email="maria.gonzalez@alu.uct.cl"
        photoUrl="https://images.unsplash.com/photo-1544005313-94ddf0286df2?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80"
        objectReports={[
          {
            title: 'LENTES DE SOL',
            status: 'En proceso',
            statusColor: 'yellow',
            building: 'EDIFICIO A',
            code: 'OP-2026-0005',
            actions: [
              { title: 'Reportado por María', subtitle: 'Hace 2 días', avatarSrc: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80' }
            ]
          }
        ]}
        incidentReports={[
          {
            location: 'BIBLIOTECA CENTRAL',
            status: 'RESUELTO',
            statusColor: 'green',
            title: 'Luz intermitente en sala de estudio',
            reporterName: 'María González Pérez',
            reportTime: 'Hace 1 semana',
            reporterAvatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80',
            description: 'El tubo fluorescente de la mesa 4 está parpadeando constantemente.',
            photoUrl: 'https://images.unsplash.com/photo-1497215848943-4710166a9089?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'
          }
        ]}
      />

      <ContactProfilePanel
        name="NOMBRE PROFESOR"
        degree="Grado Académico"
        role="Cargo Principal"
        department="Facultad y Departamento"
        office="Oficina Física"
        email="Correo@uct.cl"
        phone="Número contacto"
      />

      <ContactCard
        name="NOMBRE CONTACTO"
        role="Cargo Principal"
        department="Facultad y Departamento"
      />

      <div className="w-full max-w-4xl flex flex-col gap-4">
        <UserManagementCard
          id="showcase-1"
          name="Juan Pérez"
          email="juan.perez@uct.cl"
          role={Role.Student}
        />
        <UserManagementCard
          id="showcase-2"
          name="Carlos Hacker"
          email="carlos.h@uct.cl"
          role={Role.Teacher}
          isSuspended={true}
        />
      </div>

      <div className="w-full max-w-4xl flex flex-col gap-4">
        <MapEditorPanel />
      </div>

      <div className="w-full max-w-4xl flex flex-col gap-4">
        <TimedActionCard 
          title="Confirmar Acción Crítica"
          description="Debes esperar 5 segundos antes de poder confirmar o cancelar esta acción. Lee detenidamente."
          initialDurationMs={5000}
          options={[
            { label: 'Confirmar', color: 'red', onClick: () => alert('Confirmado!') },
            { label: 'Cancelar', color: 'gray', onClick: () => alert('Cancelado!') }
          ]}
        />
      </div>

      <ObjectReportCard
        title="OBJETO"
        status="Publicado"
        statusColor="blue"
        building="EDIFICIO 11"
        code="OP-2026-0001"
        actions={[
          { title: "Reportado por Usuario", subtitle: "Hace 24 minutos", avatarSrc: "https://i.pravatar.cc/150?img=11" },
          { title: "Recuperado por Usuario", subtitle: "Hace 12 minutos", avatarSrc: "https://i.pravatar.cc/150?img=11" }
        ]}
      />

      <IncidentCard
        location="EDIFICIO 11"
        status="SIN REVISAR"
        statusColor="red"
        photoUrl="https://images.unsplash.com/photo-1584622650111-993a426fbf0a?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80"
        title="Baño roto"
        reporterName="Juan Pérez"
        reportTime="Hace 24 minutos"
        reporterAvatar="https://i.pravatar.cc/150?img=11"
        description="Estudiantes destruyeron un baño hace unos minutos en el edificio 8..."
      />

      <Panel color="white" innerClassName="p-8 flex flex-col gap-6 items-center w-full max-w-4xl">
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-8 items-center justify-items-center w-full">
          {/* Classic Variant */}
          <div className="flex flex-col items-center gap-3 p-4 bg-gray-50 rounded-xl border border-gray-100 w-full min-h-[220px] justify-center">
            <span className="text-xs font-bold text-gray-500 uppercase tracking-wider">Classic</span>
            <LoadingSpinner size="lg" texts={UCT_LOADING_PHRASES} variant="classic" />
          </div>

          {/* Dark Variant */}
          <div className="flex flex-col items-center gap-3 p-4 bg-gray-100 rounded-xl border border-gray-200 w-full min-h-[220px] justify-center">
            <span className="text-xs font-bold text-gray-700 uppercase tracking-wider">Dark / Black</span>
            <LoadingSpinner size="lg" texts={UCT_LOADING_PHRASES} variant="dark" />
          </div>

          {/* Light Variant (on dark background container) */}
          <div className="flex flex-col items-center gap-3 p-4 bg-gray-900 rounded-xl border border-gray-800 w-full min-h-[220px] justify-center">
            <span className="text-xs font-bold text-gray-300 uppercase tracking-wider">Light / White</span>
            <LoadingSpinner size="lg" texts={UCT_LOADING_PHRASES} variant="light" />
          </div>

          <div className="flex flex-col items-center gap-3 p-4 bg-gray-50 rounded-xl border border-gray-100 w-full min-h-[220px] justify-center">
            <span className="text-xs font-bold text-gray-500 uppercase tracking-wider">Sin Texto</span>
            <LoadingSpinner size="lg" variant="classic" hideText />
          </div>
        </div>
      </Panel>

      <Panel color="white" innerClassName="p-6 flex flex-wrap gap-4 items-center">
        <Button variant="solid">Guardar</Button>
        <Button variant="outline">Cancelar</Button>
        <Button variant="ghost">Ignorar</Button>
      </Panel>

      <Panel color="white" innerClassName="p-6 flex gap-8 items-end flex-wrap">
        <NumberSelect label="Horizontal (Default)" initialValue={0} min={-5} max={5} />
        <NumberSelect label="Vertical" initialValue={10} multiplier={5} variant="vertical" />
        <NumberSelect label="Float" initialValue={1.5} multiplier={0.5} isFloat />
      </Panel>

      <Panel color="white" innerClassName="p-6 flex flex-col gap-4 min-w-[350px]">
        <Input label="Normal" placeholder="Placeholder" />
        <Input label="Con Error" placeholder="Placeholder" error="Mensaje de error" />
      </Panel>

      <Panel color="white" innerClassName="p-6 flex flex-col gap-4 min-w-[350px] relative z-20">
        <SearchInput
          label="Buscador con sugerencias"
          placeholder="Escribe 'patata', 'manzana', etc..."
          value={searchInputValue}
          onChange={setSearchInputValue}
          icon={<MapPinIcon className="w-5 h-5 text-gray-500" />}
          options={[
            { value: 'patata', label: 'Patata Frita' },
            { value: 'manzana', label: 'Manzana Roja' },
            { value: 'pera', label: 'Pera Verde' },
            { value: 'platano', label: 'Plátano' }
          ]}
        />
      </Panel>

      <Panel color="white" innerClassName="p-6 flex flex-col gap-4 min-w-[350px]">
        <Select label="Normal" options={[{ value: '1', label: 'Opción 1' }]} />
        <Select label="Con Error" error="Selecciona una opción" options={[{ value: '1', label: 'Opción 1' }]} />
      </Panel>

      <Panel color="white" innerClassName="p-6 flex gap-4 items-center">
        <NavButton to="/" label="Activo" />
        <NavButton to="/inactivo" label="Inactivo" />
      </Panel>

      <Panel color="white" innerClassName="p-6 flex gap-4 items-center">
        <SectionButton to="/" label="Mapa" icon={<MapPinIcon className="w-6 h-6" />} />
        <SectionButton to="/reportes" label="Reportes" icon={<InfoIcon className="w-6 h-6" />} />
      </Panel>

      <Panel color="white" innerClassName="p-6 flex gap-4 items-center">
        <SquareButton>
          <MapPinIcon className="w-6 h-6" />
        </SquareButton>
      </Panel>

      <Panel color="white" innerClassName="p-6 flex flex-col gap-4 min-w-[350px]">
        <CheckboxItem label="Opción 1" />
        <CheckboxItem label="Opción 2" />
      </Panel>

      <Panel color="white" innerClassName="p-6 flex gap-4 flex-wrap">
        <Tag label="Mantenimiento" color="yellow" />
        <Tag label="Cerrado" color="red" />
        <Tag label="Abierto" color="green" />
        <Tag label="Edificio" color="blue" />
      </Panel>

      <Panel color="white" innerClassName="p-8 flex flex-wrap gap-8 bg-gray-200 justify-center">
        <Panel withUctBorder innerClassName="p-4 w-56 h-56 flex items-center justify-center font-bold text-lg text-gray-700">Principal</Panel>
        <Panel color="white" innerClassName="p-4 w-56 h-56 flex items-center justify-center font-bold text-lg text-gray-700">Blanco</Panel>
        <Panel color="gray" innerClassName="p-4 w-56 h-56 flex items-center justify-center font-bold text-lg text-gray-700">Gris</Panel>
      </Panel>

      <Panel color="white" innerClassName="p-6 flex gap-8 bg-gray-200 justify-center">
        <MapMarker color="blue" icon={<MarkerRectIcon className="w-6 h-6" />} />
        <MapMarker color="red" icon={<CrossIcon className="w-6 h-6" />} />
        <MapMarker color="yellow" icon={<WarningAltIcon className="w-6 h-6" />} />
        <MapMarker color="green" icon={<CheckIcon className="w-6 h-6" />} />
      </Panel>

      <Panel color="white" innerClassName="p-6 flex flex-col gap-4">
        <IconText text="Contacto" icon={<PhoneAltIcon className="w-[1em] h-[1em]" />} />
        <IconText text="Correo" icon={<MailAltIcon className="w-[1em] h-[1em]" />} />
      </Panel>

      <Panel color="white" innerClassName="p-6 flex gap-8 items-center">
        <PhotoFrame className="w-24 h-24" />
        <PhotoFrame className="w-24 h-24" src="https://images.unsplash.com/photo-1541339907198-e08756dedf3f?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80" />
      </Panel>

      <Panel color="white" innerClassName="p-6 flex gap-8 items-center">
        <Avatar />
        <Avatar src="https://images.unsplash.com/photo-1599566150163-29194dcaad36?ixlib=rb-4.0.3&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80" />
      </Panel>

      <Panel color="white" innerClassName="p-6">
        <UserActionInfo title="Recuperado por Usuario" subtitle="Hace 12 minutos" avatarSrc="https://i.pravatar.cc/150?img=11" />
      </Panel>

      <RoomInfoCard title="SALA 11-101" type="Sala de clases" capacity={60} />

      <ScheduleCard schedule="08:00 - 22:00 hrs" className="max-w-xs" />

      <Panel color="white" innerClassName="p-6">
        <FileUpload />
      </Panel>

      <Panel color="white" innerClassName="p-6">
        <ImageGallery
          className="w-[300px] h-[150px]"
          images={[
            "https://images.unsplash.com/photo-1541339907198-e08756dedf3f?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
            "https://images.unsplash.com/photo-1523050854058-8df90110c9f1?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80"
          ]}
        />
      </Panel>

      <PublishReportCard />

      <ReportLostObjectCard />

      <BuildingDetailCard
        title="NOMBRE EDIFICIO"
        subtitle="EDIFICIO 11"
        images={[
          "https://images.unsplash.com/photo-1541339907198-e08756dedf3f?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
          "https://images.unsplash.com/photo-1523050854058-8df90110c9f1?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80"
        ]}
        schedule="08:00 - 22:00 hrs"
        floors="2 PISOS"
        services={["Punto de Reciclaje"]}
        rooms={[
          { name: "SALA 11-101", floor: 1, code: "11-101", capacity: 60 },
          { name: "SALA 11-102", floor: 1, code: "11-102", capacity: 45 },
          { name: "LABORATORIO 21-201", floor: 2, code: "21-201", capacity: 30 }
        ]}
      />

    </div>
  );
};
