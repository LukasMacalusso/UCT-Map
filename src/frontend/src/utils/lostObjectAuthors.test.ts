import { describe, it, expect, beforeEach } from 'vitest';
import { recordLostObjectAuthor, findLostObjectAuthor } from './lostObjectAuthors';

describe('lostObjectAuthors utils', () => {
  beforeEach(() => {
    localStorage.clear();
  });

  it('records and finds author of lost object', () => {
    recordLostObjectAuthor({
      userId: 'u-1',
      userName: 'Juan',
      title: 'Mochila Azul',
      structureId: 'st-10',
      createdAt: '2026-11-03T10:00:00Z',
    });

    const found = findLostObjectAuthor({
      title: '  mochila azul  ',
      structureId: 'st-10',
    });

    expect(found).toBeDefined();
    expect(found?.userId).toBe('u-1');
    expect(found?.userName).toBe('Juan');
  });

  it('returns undefined if not found or different structure', () => {
    recordLostObjectAuthor({
      userId: 'u-1',
      userName: 'Juan',
      title: 'Mochila Azul',
      structureId: 'st-10',
      createdAt: '2026-11-03T10:00:00Z',
    });

    const notFound = findLostObjectAuthor({
      title: 'Mochila Azul',
      structureId: 'st-999',
    });
    expect(notFound).toBeUndefined();
  });
});
