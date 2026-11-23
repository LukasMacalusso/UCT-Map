import { describe, it, expect, vi, beforeEach } from 'vitest';
import { useUiState } from './uiState';

describe('uiState', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    useUiState.setState({ activePanel: 'none', editorToast: null });
  });

  it('opens and closes panel', () => {
    expect(useUiState.getState().activePanel).toBe('none');
    useUiState.getState().openPanel('userProfile');
    expect(useUiState.getState().activePanel).toBe('userProfile');
    useUiState.getState().closePanel();
    expect(useUiState.getState().activePanel).toBe('none');
  });

  it('notifies editor with toast and auto-clears after timeout', () => {
    useUiState.getState().notifyEditor('Saved successfully', 'success');
    expect(useUiState.getState().editorToast?.message).toBe('Saved successfully');
    expect(useUiState.getState().editorToast?.type).toBe('success');

    vi.advanceTimersByTime(4200);
    expect(useUiState.getState().editorToast).toBeNull();
  });
});
