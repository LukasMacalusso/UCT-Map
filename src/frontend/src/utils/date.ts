const RELATIVE_UNITS: [Intl.RelativeTimeFormatUnit, number][] = [
  ['year', 31536000],
  ['month', 2592000],
  ['week', 604800],
  ['day', 86400],
  ['hour', 3600],
  ['minute', 60],
  ['second', 1],
];

const relativeFormatter = new Intl.RelativeTimeFormat('es', { numeric: 'auto' });

const DATE_PATTERN = /^(\d{1,2})[/-](\d{1,2})[/-](\d{4})(?:[ T](\d{1,2}):(\d{2})(?::(\d{2}))?)?/;

export const parseApiDate = (value: string): Date | null => {
  const match = value.trim().match(DATE_PATTERN);

  if (match) {
    const [, first, second, year, hours = '0', minutes = '0', seconds = '0'] = match;
    const a = Number(first);
    const b = Number(second);
    const dayFirst = a > 12 && b <= 12;
    const day = dayFirst ? a : b;
    const month = dayFirst ? b : a;
    const parsed = new Date(
      Date.UTC(Number(year), month - 1, day, Number(hours), Number(minutes), Number(seconds)),
    );

    return Number.isNaN(parsed.getTime()) ? null : parsed;
  }

  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
};

export const formatRelativeTime = (value: string): string => {
  const date = parseApiDate(value);

  if (!date) return value;

  const diffSeconds = Math.round((date.getTime() - Date.now()) / 1000);

  for (const [unit, secondsPerUnit] of RELATIVE_UNITS) {
    if (Math.abs(diffSeconds) >= secondsPerUnit) {
      return relativeFormatter.format(Math.round(diffSeconds / secondsPerUnit), unit);
    }
  }

  return relativeFormatter.format(diffSeconds, 'second');
};
