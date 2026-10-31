export const ComplaintStatus = {
  Claim: 0,
  Found: 1,
  Match: 2,
  Pickup: 3,
} as const;
export type ComplaintStatus = (typeof ComplaintStatus)[keyof typeof ComplaintStatus];
