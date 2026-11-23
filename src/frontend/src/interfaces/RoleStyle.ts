import type React from 'react';
import type { PageColor } from '../constants/colors';

export interface RoleStyle {
  label: string;
  color: PageColor;
  icon: React.ComponentType<React.SVGProps<SVGSVGElement>>;
}
