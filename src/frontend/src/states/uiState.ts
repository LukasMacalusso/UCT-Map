import { create } from 'zustand';

type Panel = 'none' | 'saveMapChanges' | 'discardMapChanges' | 'userProfile';

interface UiState {
  activePanel: Panel;
  openPanel: (panel: Panel) => void;
  closePanel: () => void;
}

export const useUiState = create<UiState>((set) => ({
  activePanel: 'none',
  openPanel: (panel) => set({ activePanel: panel }),
  closePanel: () => set({ activePanel: 'none' }),
}));
