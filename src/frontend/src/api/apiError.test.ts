import { describe, it, expect, vi } from 'vitest';
import axios from 'axios';
import { ApiError, toApiError } from './apiError';

describe('apiError', () => {
  it('instantiates ApiError with message and status', () => {
    const err = new ApiError('Test error', { status: 404 });
    expect(err.message).toBe('Test error');
    expect(err.status).toBe(404);
    expect(err.name).toBe('ApiError');
  });

  it('toApiError falls back to default fallback message on generic error', () => {
    const err = toApiError(new Error('Unknown'), 'Fallback message');
    expect(err.message).toBe('Fallback message');
    expect(err.status).toBeUndefined();
  });

  it('toApiError resolves statusMessages if status matches', () => {
    const axiosError = {
      isAxiosError: true,
      response: { status: 401, data: {} },
    };
    vi.spyOn(axios, 'isAxiosError').mockReturnValue(true);

    const err = toApiError(axiosError, 'Fallback', { 401: 'Unauthorized custom' });
    expect(err.message).toBe('Unauthorized custom');
    expect(err.status).toBe(401);

    vi.restoreAllMocks();
  });

  it('toApiError reads server message from string or object', () => {
    const axiosErrorString = {
      isAxiosError: true,
      response: { status: 400, data: 'Custom backend string' },
    };
    vi.spyOn(axios, 'isAxiosError').mockReturnValue(true);

    const err1 = toApiError(axiosErrorString, 'Fallback');
    expect(err1.message).toBe('Custom backend string');

    const axiosErrorObj = {
      isAxiosError: true,
      response: { status: 400, data: { detail: 'Custom detail' } },
    };
    const err2 = toApiError(axiosErrorObj, 'Fallback');
    expect(err2.message).toBe('Custom detail');

    vi.restoreAllMocks();
  });
});
