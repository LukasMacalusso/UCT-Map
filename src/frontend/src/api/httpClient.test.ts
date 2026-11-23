import { describe, it, expect, vi, beforeEach } from 'vitest';
import httpClient from './httpClient';
import { useAuthState } from '../states/authState';

describe('httpClient interceptors', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    useAuthState.setState({ token: null, user: null, role: null });
  });

  it('attaches authorization header when token exists', async () => {
    useAuthState.setState({ token: 'my-test-token' });

    // Inspect request interceptor
    // @ts-expect-error accessing private axios interceptor handlers for testing
    const requestHandler = httpClient.interceptors.request.handlers[0];
    const config = await requestHandler.fulfilled({ headers: {} });

    expect(config.headers.Authorization).toBe('Bearer my-test-token');
  });

  it('handles response errors without response (network error)', async () => {
    // @ts-expect-error accessing private axios interceptor handlers for testing
    const responseHandler = httpClient.interceptors.response.handlers[0];
    await expect(responseHandler.rejected(new Error('Network error'))).rejects.toThrow();
  });

  it('triggers logout on 401 when token is not mock', async () => {
    const logoutSpy = vi.spyOn(useAuthState.getState(), 'logout');
    useAuthState.setState({ token: 'real.jwt.token' });

    // @ts-expect-error accessing private axios interceptor handlers for testing
    const responseHandler = httpClient.interceptors.response.handlers[0];
    try {
      await responseHandler.rejected({ response: { status: 401 } });
    } catch {
      // Expected rejection
    }

    expect(logoutSpy).toHaveBeenCalled();
  });
});
