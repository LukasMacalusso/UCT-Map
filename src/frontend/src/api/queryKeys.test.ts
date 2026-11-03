import { describe, it, expect } from 'vitest';
import { queryKeys } from './queryKeys';

describe('queryKeys', () => {
  it('generates consistent keys', () => {
    expect(queryKeys.campuses).toEqual(['campuses']);
    expect(queryKeys.categories).toEqual(['categories']);
    expect(queryKeys.buildingLocations('c1')).toEqual(['buildingLocations', 'c1']);
    expect(queryKeys.buildingRooms('b1')).toEqual(['buildingRooms', 'b1']);
    expect(queryKeys.roomSearch('lab')).toEqual(['roomSearch', 'lab']);
    expect(queryKeys.structures('c1')).toEqual(['structures', 'c1']);
    expect(queryKeys.users).toEqual(['users']);
    expect(queryKeys.reports.all).toEqual(['reports']);
    expect(queryKeys.reports.list({ page: 1 })).toEqual(['reports', 'list', { page: 1 }]);
    expect(queryKeys.reports.detail('r1')).toEqual(['reports', 'detail', 'r1']);
    expect(queryKeys.lostObjects.all).toEqual(['lostObjects']);
    expect(queryKeys.lostObjects.list({ page: 1 })).toEqual(['lostObjects', 'list', { page: 1 }]);
    expect(queryKeys.teachers.officeHours('t1')).toEqual(['teachers', 't1', 'officeHours']);
    expect(queryKeys.teachers.availability('t1')).toEqual(['teachers', 't1', 'availability']);
    expect(queryKeys.teachers.workload('t1', 'f', 't')).toEqual(['teachers', 't1', 'workload', 'f', 't']);
    expect(queryKeys.teachers.meetings('t1', 'f', 't')).toEqual(['teachers', 't1', 'meetings', 'f', 't']);
  });
});
