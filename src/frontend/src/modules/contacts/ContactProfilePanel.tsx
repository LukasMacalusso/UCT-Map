import React, { useEffect, useMemo, useState } from 'react';
import { Panel } from '../../components/layout/Panel';
import { PhotoFrame } from '../../components/media/PhotoFrame';
import { IconText } from '../../components/ui/IconText';
import { Button } from '../../components/ui/Button';
import { CloseButton } from '../../components/ui/ExitButton';
import { Tag } from '../../components/ui/Tag';
import { LoadingSpinner } from '../../components/ui/LoadingSpinner';
import BuildingIcon from '../../assets/svg/icons/icon_building.svg?react';
import PhoneIcon from '../../assets/svg/icons/icon_phone.svg?react';
import MailIcon from '../../assets/svg/icons/icon_mail.svg?react';
import ClockIcon from '../../assets/svg/icons/icon_clock.svg?react';
import CalendarIcon from '../../assets/svg/icons/icon_calendar.svg?react';

import type { ScheduleItem } from '../../interfaces/ScheduleItem';
import type { OfficeHourDto } from '../../dtos/schedule/OfficeHourDto';
import type { MeetingDto } from '../../dtos/schedule/MeetingDto';
import {
  buildBookingDays,
  DURATION_OPTIONS,
  formatClock,
  formatLongDate,
  formatOfficeHour,
  sortOfficeHours,
  type BookingSlot,
} from '../../utils/schedule';

export interface ContactProfilePanelProps {
  name: string;
  degree?: string;
  role: string;
  department?: string;
  office?: string;
  email: string;
  phone?: string;
  photoUrl?: string;
  studentAttention?: string[];
  schedules?: ScheduleItem[];
  teacherId?: string;
  currentUserId?: string;
  officeHours?: OfficeHourDto[];
  meetings?: MeetingDto[];
  structureNames?: Map<string, string>;
  isLoadingSchedule?: boolean;
  isBooking?: boolean;
  bookingError?: string | null;
  bookingSuccess?: string | null;
  onBookSlot?: (params: { slot: BookingSlot; durationMinutes: number }) => void;
  onClose?: () => void;
  onViewOffice?: () => void;
}

const BOOKING_DAYS_AHEAD = 14;

export const ContactProfilePanel = ({
  name,
  degree,
  role,
  department,
  office,
  email,
  phone,
  photoUrl,
  studentAttention = [],
  schedules = [],
  teacherId,
  currentUserId,
  officeHours,
  meetings = [],
  structureNames,
  isLoadingSchedule = false,
  isBooking = false,
  bookingError = null,
  bookingSuccess = null,
  onBookSlot,
  onClose,
  onViewOffice,
}: ContactProfilePanelProps) => {
  const [durationMinutes, setDurationMinutes] = useState<number>(30);
  const [selectedDayKey, setSelectedDayKey] = useState<string>('');
  const [selectedSlotKey, setSelectedSlotKey] = useState<string>('');

  const isInteractiveBooking = Boolean(teacherId || onBookSlot || officeHours);

  const sortedOfficeHours = useMemo(
    () => sortOfficeHours(officeHours ?? []),
    [officeHours],
  );

  const bookingDays = useMemo(() => {
    if (!officeHours || officeHours.length === 0) return [];
    return buildBookingDays(officeHours, meetings, durationMinutes, BOOKING_DAYS_AHEAD);
  }, [officeHours, meetings, durationMinutes]);

  useEffect(() => {
    if (bookingDays.length === 0) {
      setSelectedDayKey('');
      setSelectedSlotKey('');
      return;
    }

    const dayStillExists = bookingDays.some((day) => day.key === selectedDayKey);
    if (!dayStillExists) {
      const firstDayWithFree = bookingDays.find((day) => day.freeSlots > 0) ?? bookingDays[0];
      setSelectedDayKey(firstDayWithFree.key);
      setSelectedSlotKey('');
    }
  }, [bookingDays, selectedDayKey]);

  const activeDay = useMemo(
    () => bookingDays.find((day) => day.key === selectedDayKey) ?? bookingDays[0] ?? null,
    [bookingDays, selectedDayKey],
  );

  const selectedSlot = useMemo(
    () => activeDay?.slots.find((slot) => slot.key === selectedSlotKey && !slot.isTaken) ?? null,
    [activeDay, selectedSlotKey],
  );

  const isSelfTeacher = Boolean(teacherId && currentUserId && teacherId === currentUserId);

  const handleBookClick = () => {
    if (!selectedSlot || !onBookSlot || isSelfTeacher) return;
    onBookSlot({ slot: selectedSlot, durationMinutes });
  };

  return (
    <Panel
      color="white"
      withUctBorder={true}
      size="xl"
      outerClassName="!w-[64rem] max-w-[95vw] !h-[52rem] max-h-[93vh]"
      innerClassName="p-6 lg:p-7 flex flex-col relative h-full overflow-hidden"
    >
      {onClose && (
        <div className="absolute top-5 right-5 z-10">
          <CloseButton onClick={onClose} variant="ghost" size="lg" />
        </div>
      )}

      {/* Top Section */}
      <div className="flex flex-col sm:flex-row gap-6 items-center sm:items-stretch text-center sm:text-left flex-shrink-0 pr-10">
        {/* Photo */}
        <PhotoFrame
          src={photoUrl}
          className="w-48 h-48 lg:w-52 lg:h-52 rounded-2xl shadow-md flex-shrink-0"
        />

        {/* Details */}
        <div className="flex flex-col flex-1 items-center sm:items-start justify-between min-w-0">
          <div className="flex flex-col items-center sm:items-start w-full min-w-0">
            <h2 className="text-2xl font-black text-gray-800 mb-1 uppercase tracking-tight">
              {name}
            </h2>

            <div className="flex flex-col gap-0.5 text-gray-600 text-sm mb-3">
              {degree && <p className="font-semibold">{degree}</p>}
              <p className="font-semibold text-page-blue">{role}</p>
              {department && <p className="text-gray-500">{department}</p>}
            </div>

            <div className="flex flex-col gap-2 mb-3 w-full">
              {office && (
                <IconText
                  icon={<BuildingIcon className="w-4 h-4 flex-shrink-0" />}
                  text={office}
                  className="!text-sm font-medium"
                />
              )}
              <IconText
                icon={<MailIcon className="w-4 h-4 flex-shrink-0" />}
                text={email}
                className="!text-sm font-medium break-all"
              />
              {phone && (
                <IconText
                  icon={<PhoneIcon className="w-4 h-4 flex-shrink-0" />}
                  text={phone}
                  className="!text-sm font-medium"
                />
              )}
            </div>
          </div>

          {onViewOffice && (
            <Button
              variant="solid"
              size="md"
              onClick={onViewOffice}
              className="!w-auto px-6 font-bold tracking-wide mt-auto"
            >
              VER OFICINA
            </Button>
          )}
        </div>
      </div>

      {/* Separator */}
      <hr className="border-t-2 border-page-blue my-4 rounded-full flex-shrink-0" />

      {/* Bottom Section */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 flex-1 min-h-0 overflow-hidden">
        {/* Students schedule / Office Hours */}
        <div className="flex flex-col gap-2.5 h-full min-h-0">
          <div className="flex items-center justify-between flex-shrink-0">
            <h3 className="text-base font-bold text-gray-800 uppercase tracking-wider flex items-center gap-2">
              <ClockIcon className="w-5 h-5 text-page-blue" />
              Atención Estudiantes
            </h3>
            {isInteractiveBooking && (
              <Tag
                label={`${sortedOfficeHours.length} ${sortedOfficeHours.length === 1 ? 'BLOQUE' : 'BLOQUES'}`}
                color={sortedOfficeHours.length > 0 ? 'blue' : 'gray'}
                className="!text-xs !px-2.5 !py-0.5"
              />
            )}
          </div>

          <div className="bg-page-gray-light p-3.5 rounded-xl flex flex-col gap-2.5 flex-1 min-h-0 overflow-y-auto">
            {isLoadingSchedule ? (
              <div className="flex-1 flex items-center justify-center py-6">
                <LoadingSpinner size="sm" text="Cargando horarios..." />
              </div>
            ) : isInteractiveBooking ? (
              sortedOfficeHours.length > 0 ? (
                sortedOfficeHours.map((block) => {
                  const locationName =
                    (block.structureRefId && structureNames?.get(block.structureRefId)) ||
                    office ||
                    'Oficina por confirmar';

                  return (
                    <div
                      key={block.id}
                      className="bg-white p-3 rounded-lg shadow-sm text-sm text-gray-700 flex flex-col gap-1 border border-gray-100 flex-shrink-0"
                    >
                      <span className="font-bold text-gray-800">
                        {formatOfficeHour(block)}
                      </span>
                      <span className="text-xs text-gray-500 flex items-center gap-1.5">
                        <BuildingIcon className="w-3.5 h-3.5 text-page-blue flex-shrink-0" />
                        {locationName}
                      </span>
                    </div>
                  );
                })
              ) : (
                <div className="flex-1 flex items-center justify-center text-center p-4 text-sm text-gray-500">
                  Este profesor aún no tiene bloques de atención registrados.
                </div>
              )
            ) : studentAttention.length > 0 ? (
              studentAttention.map((item, index) => (
                <div
                  key={index}
                  className="bg-white p-3 rounded-lg shadow-sm text-sm text-gray-700 flex items-center flex-shrink-0"
                >
                  {item}
                </div>
              ))
            ) : (
              <React.Fragment>
                <div className="bg-white p-3 rounded-lg shadow-sm min-h-[3.5rem]"></div>
                <div className="bg-white p-3 rounded-lg shadow-sm min-h-[3.5rem]"></div>
              </React.Fragment>
            )}
          </div>
        </div>

        {/* Right Column: Interactive Booking OR Static Schedules (Showcase) */}
        {isInteractiveBooking ? (
          <div className="flex flex-col gap-2.5 h-full min-h-0">
            <h3 className="text-base font-bold text-gray-800 uppercase tracking-wider flex items-center gap-2 flex-shrink-0">
              <CalendarIcon className="w-5 h-5 text-page-blue" />
              Reservar Hora
            </h3>

            <div className="bg-page-gray-light p-4 rounded-xl flex flex-col gap-3 flex-1 min-h-0 overflow-y-auto">
              {/* Duration selector */}
              <div className="flex flex-col gap-1.5 flex-shrink-0">
                <span className="text-xs font-bold text-gray-600 uppercase tracking-wide">
                  Duración de la cita
                </span>
                <div className="grid grid-cols-4 gap-2">
                  {DURATION_OPTIONS.map((mins) => {
                    const isSelected = durationMinutes === mins;
                    return (
                      <button
                        key={mins}
                        type="button"
                        onClick={() => {
                          setDurationMinutes(mins);
                          setSelectedSlotKey('');
                        }}
                        className={`py-1.5 px-2 rounded-lg text-xs font-bold transition-all cursor-pointer ${
                          isSelected
                            ? 'bg-page-blue text-white shadow-sm'
                            : 'bg-white text-gray-700 hover:bg-gray-100 border border-gray-200'
                        }`}
                      >
                        {mins} min
                      </button>
                    );
                  })}
                </div>
              </div>

              {isLoadingSchedule ? (
                <div className="flex-1 flex items-center justify-center py-6">
                  <LoadingSpinner size="sm" text="Calculando disponibilidad..." />
                </div>
              ) : bookingDays.length === 0 ? (
                <div className="bg-white p-4 rounded-lg text-sm text-gray-500 text-center flex-1 flex items-center justify-center">
                  No hay bloques disponibles en los próximos {BOOKING_DAYS_AHEAD} días para una duración de {durationMinutes} minutos.
                </div>
              ) : (
                <>
                  {/* Day selector */}
                  <div className="flex flex-col gap-1.5 flex-shrink-0">
                    <span className="text-xs font-bold text-gray-600 uppercase tracking-wide">
                      Fecha disponible
                    </span>
                    <div className="grid grid-cols-2 gap-2">
                      {bookingDays.map((day) => {
                        const isSelected = activeDay?.key === day.key;
                        return (
                          <button
                            key={day.key}
                            type="button"
                            onClick={() => {
                              setSelectedDayKey(day.key);
                              setSelectedSlotKey('');
                            }}
                            className={`flex flex-col items-start px-3 py-2 rounded-lg text-left transition-all cursor-pointer border ${
                              isSelected
                                ? 'bg-page-blue text-white border-page-blue shadow-sm'
                                : 'bg-white text-gray-700 border-gray-200 hover:bg-gray-50'
                            }`}
                          >
                            <span className="text-xs font-bold">
                              {formatLongDate(day.date)}
                            </span>
                            <span
                              className={`text-[11px] ${
                                isSelected ? 'text-blue-100' : 'text-gray-500'
                              }`}
                            >
                              {day.freeSlots} {day.freeSlots === 1 ? 'bloque libre' : 'bloques libres'}
                            </span>
                          </button>
                        );
                      })}
                    </div>
                  </div>

                  {/* Time slots */}
                  {activeDay && (
                    <div className="flex flex-col gap-1.5 flex-1 min-h-0">
                      <span className="text-xs font-bold text-gray-600 uppercase tracking-wide flex-shrink-0">
                        Horario ({formatLongDate(activeDay.date)})
                      </span>
                      <div className="grid grid-cols-2 sm:grid-cols-3 gap-2 overflow-y-auto pr-1 content-start flex-1">
                        {activeDay.slots.map((slot) => {
                          const isSelected = selectedSlot?.key === slot.key;
                          const label = `${formatClock(slot.start)} - ${formatClock(slot.end)}`;

                          return (
                            <button
                              key={slot.key}
                              type="button"
                              disabled={slot.isTaken}
                              onClick={() => setSelectedSlotKey(slot.key)}
                              className={`py-2 px-2.5 rounded-lg text-xs font-bold transition-all border ${
                                slot.isTaken
                                  ? 'bg-gray-200 text-gray-400 border-gray-200 cursor-not-allowed line-through'
                                  : isSelected
                                    ? 'bg-page-yellow text-page-dark border-page-yellow shadow-sm cursor-pointer'
                                    : 'bg-white text-gray-800 border-gray-200 hover:border-page-blue cursor-pointer'
                              }`}
                            >
                              {label}
                            </button>
                          );
                        })}
                      </div>
                    </div>
                  )}
                </>
              )}

              {bookingError && (
                <div className="bg-red-50 border border-red-200 text-red-700 text-xs font-medium px-3 py-2 rounded-lg flex-shrink-0">
                  {bookingError}
                </div>
              )}

              {bookingSuccess && (
                <div className="bg-green-50 border border-green-200 text-green-700 text-xs font-semibold px-3 py-2 rounded-lg flex-shrink-0">
                  {bookingSuccess}
                </div>
              )}

              {isSelfTeacher && (
                <div className="bg-yellow-50 border border-yellow-200 text-yellow-800 text-xs font-medium px-3 py-2 rounded-lg flex-shrink-0">
                  No puedes agendar una hora de atención contigo mismo.
                </div>
              )}

              <div className="flex justify-end pt-1 mt-auto flex-shrink-0">
                <Button
                  variant="solid"
                  color="blue"
                  size="md"
                  disabled={!selectedSlot || isBooking || isSelfTeacher || !currentUserId}
                  onClick={handleBookClick}
                  className="!w-full font-bold tracking-wide"
                >
                  {isBooking ? 'RESERVANDO...' : 'RESERVAR HORA'}
                </Button>
              </div>
            </div>
          </div>
        ) : (
          <div className="flex flex-col gap-2.5 h-full min-h-0">
            <h3 className="text-base font-bold text-gray-800 uppercase tracking-wider flex-shrink-0">Horarios</h3>
            <div className="bg-page-gray-light p-4 rounded-xl flex flex-col gap-3 flex-1 min-h-0 overflow-y-auto">
              {schedules.length > 0 ? (
                schedules.map((schedule) => (
                  <div
                    key={schedule.id}
                    className="bg-white p-4 rounded-lg shadow-sm flex flex-col flex-shrink-0"
                  >
                    <span className="font-medium text-gray-800">{schedule.course}</span>
                    <span className="text-sm text-gray-600">{schedule.time}</span>
                    {schedule.assistant && (
                      <span className="text-sm text-gray-600">Ayudante: {schedule.assistant}</span>
                    )}
                  </div>
                ))
              ) : (
                <div className="bg-white p-4 rounded-lg shadow-sm flex flex-col flex-shrink-0">
                  <span className="font-medium text-gray-800">Cálculo I</span>
                  <span className="text-sm text-gray-600">Lunes: 8:00 - 12:30 a.m</span>
                  <span className="text-sm text-gray-600">Ayudante: Foyarzo</span>
                </div>
              )}
            </div>
          </div>
        )}
      </div>
    </Panel>
  );
};
