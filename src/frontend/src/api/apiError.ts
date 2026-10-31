import axios from 'axios';

interface ApiErrorOptions {
  status?: number;
  cause?: unknown;
}

export class ApiError extends Error {
  readonly status?: number;

  constructor(message: string, { status, cause }: ApiErrorOptions = {}) {
    super(message, { cause });
    this.name = 'ApiError';
    this.status = status;
  }
}

const readServerMessage = (error: unknown): string => {
  if (!axios.isAxiosError(error)) return '';

  const data: unknown = error.response?.data;

  if (typeof data === 'string') return data.trim();

  if (data && typeof data === 'object') {
    const record = data as Record<string, unknown>;
    for (const key of ['detail', 'title', 'message']) {
      const value = record[key];
      if (typeof value === 'string' && value.trim()) return value.trim();
    }
  }

  return '';
};

export const toApiError = (
  error: unknown,
  fallback: string,
  statusMessages: Record<number, string> = {},
): ApiError => {
  const status = axios.isAxiosError(error) ? error.response?.status : undefined;

  const byStatus =
    status === undefined
      ? undefined
      : statusMessages[status] ?? (status >= 500 ? statusMessages[500] : undefined);

  return new ApiError(byStatus ?? (readServerMessage(error) || fallback), { status, cause: error });
};
