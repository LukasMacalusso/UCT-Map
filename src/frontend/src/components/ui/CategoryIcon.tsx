import React from 'react';
import UsersIcon from '../../assets/svg/icons/icon_users.svg?react';
import BuildingIcon from '../../assets/svg/icons/icon_building.svg?react';
import DoorIcon from '../../assets/svg/icons/icon_door.svg?react';
import StudyIcon from '../../assets/svg/icons/icon_study.svg?react';
import CategoryCubeIcon from '../../assets/svg/icons/icon_category_cube.svg?react';

export interface CategoryIconProps {
  icon?: string | null;
  className?: string;
}

export const CategoryIcon: React.FC<CategoryIconProps> = ({
  icon,
  className = 'w-4 h-4',
}) => {
  const normalized = (icon ?? '').trim().toLowerCase();

  switch (normalized) {
    case 'book':
    case 'libro':
      return (
        <svg
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
          className={className}
        >
          <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20" />
          <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z" />
        </svg>
      );

    case 'computer':
    case 'computador':
    case 'laptop':
    case 'pc':
      return (
        <svg
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
          className={className}
        >
          <rect x="2" y="3" width="20" height="14" rx="2" ry="2" />
          <line x1="2" y1="20" x2="22" y2="20" />
        </svg>
      );

    case 'coffee':
    case 'cafe':
    case 'cafeteria':
      return (
        <svg
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
          className={className}
        >
          <path d="M18 8h1a4 4 0 0 1 0 8h-1" />
          <path d="M2 8h16v9a4 4 0 0 1-4 4H6a4 4 0 0 1-4-4V8z" />
          <line x1="6" y1="1" x2="6" y2="4" />
          <line x1="10" y1="1" x2="10" y2="4" />
          <line x1="14" y1="1" x2="14" y2="4" />
        </svg>
      );

    case 'wifi':
    case 'internet':
      return (
        <svg
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
          className={className}
        >
          <path d="M5 12.55a11 11 0 0 1 14.08 0" />
          <path d="M1.42 9a16 16 0 0 1 21.16 0" />
          <path d="M8.53 16.11a6 6 0 0 1 6.95 0" />
          <circle cx="12" cy="20" r="1" fill="currentColor" />
        </svg>
      );

    case 'bath':
    case 'baño':
    case 'wc':
    case 'restroom':
      return (
        <svg
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
          className={className}
        >
          <circle cx="12" cy="4.5" r="2.5" />
          <path d="M9 22v-6H7l3-7h4l3 7h-2v6" />
        </svg>
      );

    case 'users':
    case 'personas':
    case 'comunidad':
      return <UsersIcon className={className} />;

    case 'building':
    case 'edificio':
      return <BuildingIcon className={className} />;

    case 'door':
    case 'puerta':
    case 'sala':
      return <DoorIcon className={className} />;

    case 'study':
    case 'estudio':
      return <StudyIcon className={className} />;

    default:
      return <CategoryCubeIcon className={className} />;
  }
};
