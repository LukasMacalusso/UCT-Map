export type PageColor = 'blue' | 'red' | 'yellow' | 'dark' | 'gray' | 'green' | 'white' | 'transparent' | 'purple';

export const bgPageColors: Record<PageColor, string> = {
  blue: "bg-page-blue",
  red: "bg-page-red",
  yellow: "bg-page-yellow",
  dark: "bg-page-dark",
  gray: "bg-page-gray",
  green: "bg-page-green",
  white: "bg-page-white",
  transparent: "bg-transparent",
  purple: "bg-page-purple",
};

export const textPageColors: Record<PageColor, string> = {
  blue: "text-page-blue",
  red: "text-page-red",
  yellow: "text-page-yellow",
  dark: "text-page-dark",
  gray: "text-page-gray",
  green: "text-page-green",
  white: "text-page-white",
  transparent: "text-transparent",
  purple: "text-page-purple",
};

export const borderPageColors: Record<PageColor, string> = {
  blue: "border-page-blue",
  red: "border-page-red",
  yellow: "border-page-yellow",
  dark: "border-page-dark",
  gray: "border-page-gray",
  green: "border-page-green",
  white: "border-page-white",
  transparent: "border-transparent",
  purple: "border-page-purple",
};

export const ringPageColors: Record<PageColor, string> = {
  blue: "focus:ring-page-blue",
  red: "focus:ring-page-red",
  yellow: "focus:ring-page-yellow",
  dark: "focus:ring-page-dark",
  gray: "focus:ring-page-gray",
  green: "focus:ring-page-green",
  white: "focus:ring-page-white",
  transparent: "focus:ring-transparent",
  purple: "focus:ring-page-purple",
};

export const hoverBgPageColors: Record<PageColor, string> = {
  blue: "hover:bg-page-blue/10",
  red: "hover:bg-page-red/10",
  yellow: "hover:bg-page-yellow/10",
  dark: "hover:bg-page-dark/10",
  gray: "hover:bg-page-gray/10",
  green: "hover:bg-page-green/10",
  white: "hover:bg-white/10",
  transparent: "hover:bg-transparent",
  purple: "hover:bg-page-purple/10",
};

export const solidButtonConfig: Record<PageColor, { text: string; hover: string }> = {
  blue: { text: "text-page-white", hover: "hover:brightness-110" },
  red: { text: "text-page-white", hover: "hover:brightness-110" },
  yellow: { text: "text-page-dark", hover: "hover:brightness-95" },
  dark: { text: "text-page-white", hover: "hover:brightness-110" },
  gray: { text: "text-page-dark", hover: "hover:brightness-95" },
  green: { text: "text-page-white", hover: "hover:brightness-110" },
  white: { text: "text-page-dark", hover: "hover:bg-gray-50" },
  transparent: { text: "text-inherit", hover: "" },
  purple: { text: "text-page-white", hover: "hover:brightness-110" },
};
