import { create } from 'zustand';

type Panel = 'none' | 'saveMapChanges' | 'discardMapChanges' | 'userProfile';

export interface EditorToast {
  id: number;
  message: string;
  type?: 'success' | 'info' | 'error';
}

interface UiState {
  activePanel: Panel;
  openPanel: (panel: Panel) => void;
  closePanel: () => void;
  editorToast: EditorToast | null;
  setEditorToast: (toast: EditorToast | null) => void;
  notifyEditor: (message: string, type?: 'success' | 'info' | 'error') => void;
}

let toastTimer: ReturnType<typeof setTimeout> | null = null;
let toastCounter = 0;

export const useUiState = create<UiState>((set) => ({
  activePanel: 'none',
  openPanel: (panel) => set({ activePanel: panel }),
  closePanel: () => set({ activePanel: 'none' }),
  editorToast: null,
  setEditorToast: (toast) => set({ editorToast: toast }),
  notifyEditor: (message, type = 'success') => {
    if (toastTimer) clearTimeout(toastTimer);
    toastCounter += 1;
    set({ editorToast: { id: toastCounter, message, type } });
    toastTimer = setTimeout(() => {
      set({ editorToast: null });
    }, 4100);
  },
}));
