import { Select } from '../../components/ui/Select';
import type { MeetingDto, MeetingStatusName } from '../../dtos/schedule/MeetingDto';
import { useUpdateMeetingStatus } from '../../hooks/useSchedule';

const STATUS_LABELS: Record<MeetingStatusName, string> = {
  Pending: 'Pendiente',
  Confirmed: 'Confirmada',
  Cancelled: 'Cancelada',
  Completed: 'Completada',
};

const isMeetingStatus = (value: string): value is MeetingStatusName =>
  Object.prototype.hasOwnProperty.call(STATUS_LABELS, value);

const buildOptions = (
  status: MeetingStatusName,
  isTeacher: boolean,
  isStudent: boolean,
): { value: string; label: string }[] => {
  const options = [{ value: status, label: STATUS_LABELS[status] }];

  if (isTeacher && status === 'Pending') {
    options.push(
      { value: 'Confirmed', label: STATUS_LABELS.Confirmed },
      { value: 'Cancelled', label: STATUS_LABELS.Cancelled },
    );
  }

  if (isTeacher && status === 'Confirmed') {
    options.push(
      { value: 'Completed', label: STATUS_LABELS.Completed },
      { value: 'Cancelled', label: STATUS_LABELS.Cancelled },
    );
  }

  if (isStudent && (status === 'Pending' || status === 'Confirmed')) {
    options.push({ value: 'Cancelled', label: STATUS_LABELS.Cancelled });
  }

  return options;
};

interface MeetingStatusSelectProps {
  meeting: MeetingDto;
  isTeacher: boolean;
  isStudent: boolean;
}

export const MeetingStatusSelect = ({
  meeting,
  isTeacher,
  isStudent,
}: MeetingStatusSelectProps) => {
  const updateMeetingStatus = useUpdateMeetingStatus();
  const status = isMeetingStatus(meeting.status) ? meeting.status : null;

  if (!status) {
    return (
      <span className="text-xs font-semibold text-gray-600 uppercase">
        {meeting.status}
      </span>
    );
  }

  const options = buildOptions(status, isTeacher, isStudent);
  const isLocked = options.length === 1 || updateMeetingStatus.isPending;

  const handleChange = (value: string) => {
    if (!isMeetingStatus(value) || value === meeting.status) return;
    updateMeetingStatus.mutate({ id: meeting.id, status: value });
  };

  return (
    <div className="w-44 flex-shrink-0">
      <Select
        options={options}
        value={status}
        onChange={handleChange}
        disabled={isLocked}
        error={updateMeetingStatus.error?.message}
        className={`!py-2 !px-3 !text-xs ${isLocked ? '!pointer-events-none opacity-70' : ''}`}
      />
    </div>
  );
};
