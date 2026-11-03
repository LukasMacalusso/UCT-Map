import { useState } from 'react';
import { Panel } from '../../components/layout/Panel';
import { Input } from '../../components/ui/Input';
import { Select } from '../../components/ui/Select';
import { FileUpload } from '../../components/ui/FileUpload';
import { Button } from '../../components/ui/Button';
import { CloseButton } from '../../components/ui/ExitButton';
import BuildingIcon from '../../assets/svg/icons/icon_building.svg?react';
import { useCampuses, useStructures } from '../../hooks/useCampus';

export interface ReportLostObjectData {
  title: string;
  description?: string;
  structureId: string;
  files: File[];
}

interface ReportLostObjectCardProps {
  isSubmitting?: boolean;
  error?: string | null;
  onPublish?: (data: ReportLostObjectData) => void;
  onDiscard?: () => void;
  initialCampusId?: string;
  initialStructureName?: string;
}

export const ReportLostObjectCard = ({
  isSubmitting = false,
  error,
  onPublish,
  onDiscard,
  initialCampusId,
  initialStructureName,
}: ReportLostObjectCardProps) => {
  const [title, setTitle] = useState('');
  const [campusSelection, setCampusSelection] = useState(initialCampusId ?? '');
  const [structureSelection, setStructureSelection] = useState('');
  const [isInitialStructureActive, setIsInitialStructureActive] = useState(true);
  const [files, setFiles] = useState<File[]>([]);

  const { data: campuses = [] } = useCampuses();
  const campusId = campusSelection || campuses[0]?.id || '';

  const { data: structures = [] } = useStructures(campusId || undefined, !!campusId);
  const initialStructure = initialStructureName
    ? structures.find((structure) => structure.name === initialStructureName)
    : undefined;
  const structureId =
    (isInitialStructureActive ? initialStructure?.id : undefined) ||
    structureSelection ||
    structures[0]?.id ||
    '';

  const handleCampusChange = (value: string) => {
    setCampusSelection(value);
    setStructureSelection('');
    setIsInitialStructureActive(false);
  };

  const handleStructureChange = (value: string) => {
    setIsInitialStructureActive(false);
    setStructureSelection(value);
  };

  const campusOptions = campuses.map((campus) => ({ value: campus.id, label: campus.name }));
  const structureOptions = structures.map((structure) => ({
    value: structure.id,
    label: structure.name,
  }));

  const canPublish = title.trim() !== '' && structureId !== '' && !isSubmitting;

  const handlePublish = () => {
    if (!canPublish || !onPublish) return;

    onPublish({
      title: title.trim(),
      description: '',
      structureId,
      files,
    });
  };

  return (
    <Panel withUctBorder color="white" outerClassName="rounded-3xl max-w-2xl w-full" innerClassName="p-8 flex flex-col gap-5">
      <div className="flex items-center justify-between w-full">
        <h2 className="text-3xl font-black text-gray-800 tracking-tight">REPORTAR OBJETO PERDIDO</h2>
        <CloseButton variant="ghost" size="lg" onClick={onDiscard} />
      </div>

      <Input
        labelColor="text-gray-700"
        placeholder="¿QUÉ SE PERDIÓ?"
        value={title}
        onChange={(e) => setTitle(e.target.value)}
      />

      <FileUpload
        maxFiles={3}
        label="ARRASTRA MÁXIMO 3 IMÁGENES DEL OBJETO"
        height="h-52"
        onFilesChange={setFiles}
      />

      <div className="flex flex-wrap sm:flex-nowrap gap-4">
        <div className="flex-1 min-w-[200px]">
          <Select
            labelColor="text-gray-700"
            options={campusOptions}
            value={campusId}
            onChange={handleCampusChange}
            icon={<BuildingIcon className="w-5 h-5 text-gray-700" />}
          />
        </div>

        <div className="flex-1 min-w-[180px]">
          <Select
            labelColor="text-gray-700"
            options={structureOptions}
            value={structureId}
            onChange={handleStructureChange}
            icon={<BuildingIcon className="w-5 h-5 text-gray-700" />}
          />
        </div>
      </div>

      {campusId && structureOptions.length === 0 && (
        <p className="text-xs font-medium text-gray-500">
          Este campus no tiene edificios registrados.
        </p>
      )}

      {error && <p className="text-sm font-medium text-red-500">{error}</p>}

      <p className="text-xs text-gray-600 leading-relaxed font-medium">
        Este reporte ayudará a la comunidad a buscar e identificar tu objeto. La publicación de reportes falsos puede acarrear sanciones en el sistema.
      </p>

      <div className="flex items-center justify-end gap-4 pt-2">
        <Button
          color="red"
          variant="solid"
          size="md"
          width="md"
          onClick={onDiscard}
          className="font-bold tracking-wide"
        >
          Cancelar
        </Button>

        <Button
          color="blue"
          variant="solid"
          size="md"
          width="md"
          onClick={handlePublish}
          disabled={!canPublish}
          className="font-bold tracking-wide"
        >
          {isSubmitting ? 'Reportando...' : 'Reportar Perdido'}
        </Button>
      </div>
    </Panel>
  );
};
