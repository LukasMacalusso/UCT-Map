import { useEffect, useRef, type ReactNode } from 'react';
import { createPortal } from 'react-dom';

interface ModalOverlayProps {
  isOpen: boolean;
  onClose: () => void;
  children: ReactNode;
  className?: string;
}

const FOCUSABLE_SELECTOR = [
  'a[href]',
  'button:not([disabled])',
  'input:not([disabled])',
  'select:not([disabled])',
  'textarea:not([disabled])',
  '[tabindex]:not([tabindex="-1"])',
].join(', ');

let scrollLockCount = 0;
let previousBodyOverflow = '';

const lockBodyScroll = () => {
  if (scrollLockCount === 0) {
    previousBodyOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
  }
  scrollLockCount += 1;
};

const unlockBodyScroll = () => {
  scrollLockCount = Math.max(0, scrollLockCount - 1);
  if (scrollLockCount === 0) {
    document.body.style.overflow = previousBodyOverflow;
  }
};

export const ModalOverlay = ({ isOpen, onClose, children, className = '' }: ModalOverlayProps) => {
  const containerRef = useRef<HTMLDivElement | null>(null);
  const onCloseRef = useRef(onClose);

  useEffect(() => {
    onCloseRef.current = onClose;
  }, [onClose]);

  useEffect(() => {
    if (!isOpen) return;

    const previouslyFocused = document.activeElement as HTMLElement | null;

    const getFocusableElements = () =>
      Array.from(
        containerRef.current?.querySelectorAll<HTMLElement>(FOCUSABLE_SELECTOR) ?? []
      );

    const focusFrame = requestAnimationFrame(() => {
      const [firstFocusable] = getFocusableElements();
      (firstFocusable ?? containerRef.current)?.focus();
    });

    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        event.preventDefault();
        onCloseRef.current();
        return;
      }

      if (event.key !== 'Tab' || !containerRef.current) return;

      const focusableElements = getFocusableElements();
      const firstFocusable = focusableElements[0];
      const lastFocusable = focusableElements[focusableElements.length - 1];
      const activeElement = document.activeElement;

      if (!firstFocusable) {
        event.preventDefault();
        containerRef.current.focus();
        return;
      }

      const focusIsInside = containerRef.current.contains(activeElement);

      if (event.shiftKey && (!focusIsInside || activeElement === firstFocusable)) {
        event.preventDefault();
        lastFocusable.focus();
      } else if (!event.shiftKey && (!focusIsInside || activeElement === lastFocusable)) {
        event.preventDefault();
        firstFocusable.focus();
      }
    };

    document.addEventListener('keydown', handleKeyDown);
    lockBodyScroll();

    return () => {
      cancelAnimationFrame(focusFrame);
      document.removeEventListener('keydown', handleKeyDown);
      unlockBodyScroll();
      previouslyFocused?.focus?.();
    };
  }, [isOpen]);

  if (!isOpen) return null;

  return createPortal(
    <div
      className="fixed inset-0 z-[100] flex items-center justify-center p-4 backdrop-blur-sm bg-black/40 opacity-100 transition-all duration-300 motion-reduce:transition-none starting:opacity-0 starting:bg-transparent"
      onClick={(event) => {
        if (event.target === event.currentTarget) onCloseRef.current();
      }}
    >
      <div
        ref={containerRef}
        role="dialog"
        aria-modal="true"
        tabIndex={-1}
        className={`max-h-full outline-none opacity-100 scale-100 translate-y-0 transition-all duration-300 motion-reduce:transition-none starting:opacity-0 starting:scale-95 starting:translate-y-4 ${className}`.trim()}
      >
        {children}
      </div>
    </div>,
    document.body
  );
};
