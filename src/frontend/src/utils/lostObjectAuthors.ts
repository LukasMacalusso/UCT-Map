import type { LostObjectDto } from '../dtos/incident/objects/LostObjectDto';

const STORAGE_KEY = 'uct_lost_object_authors';

export interface LostObjectAuthorRecord {
  userId: string;
  userName: string;
  userAvatar?: string;
  title: string;
  structureId: string;
  createdAt: string;
}

const readRecords = (): LostObjectAuthorRecord[] => {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? (JSON.parse(raw) as LostObjectAuthorRecord[]) : [];
  } catch {
    return [];
  }
};

export const recordLostObjectAuthor = (record: LostObjectAuthorRecord): void => {
  try {
    const current = readRecords();
    current.unshift(record);
    localStorage.setItem(STORAGE_KEY, JSON.stringify(current.slice(0, 200)));
  } catch {
    // Ignore storage errors
  }
};

export const findLostObjectAuthor = (
  lostObject: Pick<LostObjectDto, 'title' | 'structureId'>,
): LostObjectAuthorRecord | undefined => {
  const records = readRecords();
  return records.find(
    (rec) =>
      rec.title.trim().toLowerCase() === lostObject.title.trim().toLowerCase() &&
      rec.structureId === lostObject.structureId,
  );
};
