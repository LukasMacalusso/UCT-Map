import React from 'react';
import { Panel } from '../../components/layout/Panel';
import { PhotoFrame } from '../../components/media/PhotoFrame';
import { IconText } from '../../components/ui/IconText';
import { Button } from '../../components/ui/Button';
import BuildingIcon from '../../assets/svg/icons/icon_building.svg?react';
import PhoneIcon from '../../assets/svg/icons/icon_phone.svg?react';
import MailIcon from '../../assets/svg/icons/icon_mail.svg?react';

import type { ScheduleItem } from '../../interfaces/ScheduleItem';

export interface ContactProfilePanelProps {
  name: string;
  degree: string;
  role: string;
  department: string;
  office: string;
  email: string;
  phone: string;
  photoUrl?: string;
  studentAttention?: string[];
  schedules?: ScheduleItem[];
  onClose?: () => void;
  onViewOffice?: () => void;
}

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
  onClose,
  onViewOffice,
}: ContactProfilePanelProps) => {
  return (
    <Panel color="white" withUctBorder={true} onClose={onClose} size="lg" innerClassName="p-6 lg:p-8 flex flex-col max-h-[88vh] overflow-y-auto">
      {/* Top Section */}
      <div className="flex flex-col sm:flex-row gap-6 items-center sm:items-start text-center sm:text-left">
        {/* Photo */}
        <PhotoFrame src={photoUrl} className="w-40 h-40 lg:w-48 lg:h-48 rounded-2xl shadow-md" />

        {/* Details */}
        <div className="flex flex-col flex-1 items-center sm:items-start min-w-0">
          <h2 className="text-2xl font-black text-gray-800 mb-1 uppercase tracking-tight">{name}</h2>

          <div className="flex flex-col gap-0.5 text-gray-600 text-sm mb-4">
            <p className="font-semibold">{degree}</p>
            <p>{role}</p>
            <p className="text-gray-500">{department}</p>
          </div>

          <div className="flex flex-col gap-2.5 mb-5 w-full">
            <IconText icon={<BuildingIcon className="w-4 h-4 flex-shrink-0" />} text={office} className="!text-sm font-medium" />
            <IconText icon={<MailIcon className="w-4 h-4 flex-shrink-0" />} text={email} className="!text-sm font-medium break-all" />
            <IconText icon={<PhoneIcon className="w-4 h-4 flex-shrink-0" />} text={phone} className="!text-sm font-medium" />
          </div>

          <Button variant="solid" size="md" onClick={onViewOffice} className="w-max px-6 font-bold tracking-wide">
            VER OFICINA
          </Button>
        </div>
      </div>

      {/* Separator */}
      <hr className="border-t-2 border-page-blue my-6 rounded-full" />

      {/* Bottom Section */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Students schedule */}
        <div className="flex flex-col gap-2.5">
          <h3 className="text-base font-bold text-gray-800 uppercase tracking-wider">Atención Estudiantes</h3>
          <div className="bg-page-gray-light p-3.5 rounded-xl flex flex-col gap-2.5 min-h-[140px]">
            {studentAttention.length > 0 ? (
              studentAttention.map((item, index) => (
                <div key={index} className="bg-white p-3 rounded-lg shadow-sm text-sm text-gray-700 flex items-center">
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

        {/* Schedule */}
        <div className="flex flex-col gap-2.5">
          <h3 className="text-base font-bold text-gray-800 uppercase tracking-wider">Horarios</h3>
          <div className="bg-page-gray-light p-4 rounded-xl flex flex-col gap-3 min-h-[150px]">
            {schedules.length > 0 ? (
              schedules.map((schedule) => (
                <div key={schedule.id} className="bg-white p-4 rounded-lg shadow-sm flex flex-col">
                  <span className="font-medium text-gray-800">{schedule.course}</span>
                  <span className="text-sm text-gray-600">{schedule.time}</span>
                  {schedule.assistant && (
                    <span className="text-sm text-gray-600">Ayudante: {schedule.assistant}</span>
                  )}
                </div>
              ))
            ) : (
              <div className="bg-white p-4 rounded-lg shadow-sm flex flex-col">
                <span className="font-medium text-gray-800">Cálculo I</span>
                <span className="text-sm text-gray-600">Lunes: 8:00 - 12:30 a.m</span>
                <span className="text-sm text-gray-600">Ayudante: Foyarzo</span>
              </div>
            )}
          </div>
        </div>
      </div>
    </Panel>
  );
};
