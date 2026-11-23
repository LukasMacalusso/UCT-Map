import { create } from 'zustand';

interface NavState {
  isExpanded: boolean;
  isHidden: boolean;
  setIsExpanded: (expanded: boolean) => void;
  setIsHidden: (hidden: boolean) => void;
}

export const useNavStore = create<NavState>((set) => ({
  isExpanded: false,
  isHidden: false,
  setIsExpanded: (expanded) => set({ isExpanded: expanded }),
  setIsHidden: (hidden) => set({ isHidden: hidden, isExpanded: false }),
}));
