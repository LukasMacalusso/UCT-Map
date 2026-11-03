import { describe, it, expect } from 'vitest';
import { useNavStore } from './navState';

describe('navState', () => {
  it('updates expanded and hidden states', () => {
    useNavStore.getState().setIsExpanded(true);
    expect(useNavStore.getState().isExpanded).toBe(true);

    useNavStore.getState().setIsHidden(true);
    expect(useNavStore.getState().isHidden).toBe(true);
    expect(useNavStore.getState().isExpanded).toBe(false);
  });
});
