interface PaginationProps {
  currentPage: number;
  totalPages: number;
  onPageChange: (page: number) => void;
  className?: string;
}

type PageItem = number | 'start-ellipsis' | 'end-ellipsis';

const range = (from: number, to: number): number[] =>
  Array.from({ length: to - from + 1 }, (_, i) => from + i);

const getPageItems = (currentPage: number, totalPages: number): PageItem[] => {
  if (totalPages <= 5) return range(1, totalPages);

  const left = Math.max(currentPage - 1, 1);
  const right = Math.min(currentPage + 1, totalPages);
  const showLeftEllipsis = left > 2;
  const showRightEllipsis = right < totalPages - 1;

  if (!showLeftEllipsis && showRightEllipsis) {
    return [...range(1, 4), 'end-ellipsis', totalPages];
  }
  if (showLeftEllipsis && !showRightEllipsis) {
    return [1, 'start-ellipsis', ...range(totalPages - 3, totalPages)];
  }
  return [1, 'start-ellipsis', ...range(left, right), 'end-ellipsis', totalPages];
};

const baseButton =
  'flex items-center justify-center w-11 h-11 rounded-2xl font-bold text-sm transition-all duration-200 active:scale-95 select-none';

const navButtonBase =
  'flex items-center justify-center w-11 h-8 rounded-2xl font-bold transition-all duration-200 active:scale-95 select-none';

export const Pagination = ({
  currentPage,
  totalPages,
  onPageChange,
  className = '',
}: PaginationProps) => {
  if (totalPages <= 1) return null;

  const canPrev = currentPage > 1;
  const canNext = currentPage < totalPages;
  const items = getPageItems(currentPage, totalPages);

  const navButton = (enabled: boolean) =>
    `${navButtonBase} ${
      enabled
        ? 'bg-page-yellow text-page-dark hover:brightness-95 shadow-sm cursor-pointer'
        : 'bg-white/40 text-page-blue/40 cursor-not-allowed'
    }`;

  const renderNavButton = (
    enabled: boolean,
    label: string,
    targetPage: number,
    path: string
  ) => (
    <button
      type="button"
      onClick={() => enabled && onPageChange(targetPage)}
      disabled={!enabled}
      aria-label={label}
      title={label}
      className={navButton(enabled)}
    >
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" className="w-5 h-5">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.5" d={path} />
      </svg>
    </button>
  );

  return (
    <nav
      aria-label="Paginación"
      className={`flex flex-col items-center gap-2 ${className}`}
    >
      {renderNavButton(canPrev, 'Primera página', 1, 'M5 11l7-7 7 7M5 18l7-7 7 7')}

      {renderNavButton(canPrev, 'Página anterior', currentPage - 1, 'M5 15l7-7 7 7')}

      {items.map((item) =>
        typeof item === 'number' ? (
          <button
            key={item}
            type="button"
            onClick={() => onPageChange(item)}
            aria-label={`Ir a la página ${item}`}
            aria-current={item === currentPage ? 'page' : undefined}
            className={`${baseButton} ${
              item === currentPage
                ? 'bg-page-blue text-white shadow-md'
                : 'bg-white text-page-blue hover:bg-gray-50 shadow-sm cursor-pointer'
            }`}
          >
            {item}
          </button>
        ) : (
          <span
            key={item}
            aria-hidden="true"
            className="flex items-center justify-center w-11 h-6 text-page-blue/50 font-bold"
          >
            ···
          </span>
        )
      )}

      {renderNavButton(canNext, 'Página siguiente', currentPage + 1, 'M19 9l-7 7-7-7')}

      {renderNavButton(canNext, 'Última página', totalPages, 'M19 13l-7 7-7-7M19 6l-7 7-7-7')}
    </nav>
  );
};
