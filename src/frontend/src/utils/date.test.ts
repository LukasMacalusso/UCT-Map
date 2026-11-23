import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { parseApiDate, formatRelativeTime } from './date';

describe('date utils', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date('2026-11-03T12:00:00Z'));
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  describe('parseApiDate', () => {
    it('parses dd/mm/yyyy formatted string', () => {
      const date = parseApiDate('25/12/2026 15:30:00');
      expect(date).not.toBeNull();
      expect(date?.getUTCFullYear()).toBe(2026);
      expect(date?.getUTCMonth()).toBe(11);
      expect(date?.getUTCDate()).toBe(25);
      expect(date?.getUTCHours()).toBe(15);
      expect(date?.getUTCMinutes()).toBe(30);
    });

    it('parses mm/dd/yyyy formatted string when day is <= 12', () => {
      const date = parseApiDate('05/10/2026');
      expect(date).not.toBeNull();
      expect(date?.getUTCFullYear()).toBe(2026);
    });

    it('parses ISO date strings', () => {
      const date = parseApiDate('2026-11-03T10:00:00Z');
      expect(date).not.toBeNull();
      expect(date?.toISOString()).toBe('2026-11-03T10:00:00.000Z');
    });

    it('returns null for invalid date string', () => {
      expect(parseApiDate('invalid-date-string')).toBeNull();
    });
  });

  describe('formatRelativeTime', () => {
    it('returns the input string if date is unparseable', () => {
      expect(formatRelativeTime('not-a-date')).toBe('not-a-date');
    });

    it('formats seconds ago', () => {
      const past = new Date(Date.now() - 30 * 1000).toISOString();
      const formatted = formatRelativeTime(past);
      expect(formatted).toContain('30');
    });

    it('formats minutes ago', () => {
      const past = new Date(Date.now() - 10 * 60 * 1000).toISOString();
      const formatted = formatRelativeTime(past);
      expect(formatted).toContain('10');
    });

    it('formats hours ago', () => {
      const past = new Date(Date.now() - 3 * 3600 * 1000).toISOString();
      const formatted = formatRelativeTime(past);
      expect(formatted).toContain('3');
    });

    it('formats days ago', () => {
      const past = new Date(Date.now() - 2 * 86400 * 1000).toISOString();
      const formatted = formatRelativeTime(past);
      expect(formatted).toBe('anteayer');
    });

    it('formats weeks ago', () => {
      const past = new Date(Date.now() - 2 * 7 * 86400 * 1000).toISOString();
      const formatted = formatRelativeTime(past);
      expect(formatted).toContain('semana');
    });

    it('formats months ago', () => {
      const past = new Date(Date.now() - 60 * 86400 * 1000).toISOString();
      const formatted = formatRelativeTime(past);
      expect(formatted).toContain('mes');
    });

    it('formats years ago', () => {
      const past = new Date(Date.now() - 400 * 86400 * 1000).toISOString();
      const formatted = formatRelativeTime(past);
      expect(formatted).toBe('el año pasado');
    });
  });
});
