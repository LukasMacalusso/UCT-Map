import GhostIcon from '../../assets/svg/icons/icon_ghost.svg?react';

export interface EmptyStateProps {
  message: string;
}

export const EmptyState = ({ message }: EmptyStateProps) => {
  return (
    <div className="flex flex-col items-center justify-center w-full py-16 gap-8 opacity-70">
      <div className="animate-float-up-down">
        <GhostIcon className="w-32 h-32 text-gray-400 origin-center drop-shadow-md" />
      </div>
      <div className="text-lg font-normal text-gray-500 tracking-widest uppercase text-center">
        {message}
      </div>
    </div>
  );
};
