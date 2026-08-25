const PREFIX = 'seekbox_';

export function loadLocal(key: string): string | null {
  if (typeof localStorage === 'undefined') return null;
  return localStorage.getItem(PREFIX + key);
}

export function saveLocal(key: string, value: string): void {
  localStorage.setItem(PREFIX + key, value);
}
