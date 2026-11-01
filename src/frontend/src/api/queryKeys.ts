import type { LostObjectSearchParams } from "../dtos/incident/objects/LostObjectSearchParams";
import type { ReportSearchParams } from "../dtos/incident/reports/ReportSearchParams";

export const queryKeys = {
  campuses: ['campuses'] as const,
  buildingLocations: (campusId?: string) => ['buildingLocations', campusId] as const,
  buildingRooms: (buildingId?: string) => ['buildingRooms', buildingId] as const,
  roomSearch: (term: string) => ['roomSearch', term] as const,
  structures: (campusId?: string) => ['structures', campusId] as const,

  users: ['users'] as const,

  reports: {
    all: ['reports'] as const,
    list: (params: ReportSearchParams) => ['reports', 'list', params] as const,
    detail: (id: string) => ['reports', 'detail', id] as const,
  },

  lostObjects: {
    all: ['lostObjects'] as const,
    list: (params: LostObjectSearchParams) => ['lostObjects', 'list', params] as const,
  },

  teachers: {
    all: ["teachers"] as const,
    officeHours: (teacherId?: string) =>
      ["teachers", teacherId ?? "all", "officeHours"] as const,
    availability: (teacherId: string) => ["teachers", teacherId, "availability"] as const,
    workload: (teacherId: string, from: string, to: string) =>
      ["teachers", teacherId, "workload", from, to] as const,
    meetings: (teacherId?: string, from?: string, to?: string) =>
      ["teachers", teacherId ?? "all", "meetings", from, to] as const,
  },
};
