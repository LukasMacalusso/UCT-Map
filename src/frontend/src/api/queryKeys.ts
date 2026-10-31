export const queryKeys = {
  campuses: ['campuses'] as const,
  buildingLocations: (campusId?: string) => ['buildingLocations', campusId] as const,
  buildingRooms: (buildingId?: string) => ['buildingRooms', buildingId] as const,
  roomSearch: (term: string) => ['roomSearch', term] as const,
  users: ['users'] as const,
};
