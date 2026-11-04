import { randomUUID } from 'node:crypto';

export const kinds = new Set(['comment', 'follow', 'rose', 'necklace', 'donut', 'heart']);
export function mapping(value, assets = false) {
  const result = JSON.parse(value || '{}');
  if (!result || Array.isArray(result) || typeof result !== 'object') throw Error('Invalid mapping');
  for (const [key, val] of Object.entries(result)) {
    if (!key || typeof val !== 'string' || (assets ? !/^\d+$/.test(val) : !['rose','necklace','donut','heart'].includes(val))) throw Error('Invalid mapping entry');
  }
  return result;
}
export function username(value) {
  if (typeof value !== 'string') return null;
  const name = value.trim().replace(/^@/, '').toLowerCase();
  return /^[a-z0-9_][a-z0-9_.]{0,23}$/.test(name) ? name : null;
}
export function normalize(type, data, gifts = {}, assets = {}) {
  if (!data || typeof data !== 'object') return null;
  const user = data.user || data;
  if (typeof user.uniqueId !== 'string' || !user.uniqueId) return null;
  let kind = type;
  if (type === 'gift') {
    if (Number(data.giftType ?? data.giftDetails?.giftType) === 1 && !data.repeatEnd) return null;
    kind = Object.hasOwn(gifts, String(data.giftId)) ? gifts[String(data.giftId)] : null;
    // shortcut: only verified gift IDs are accepted; populate GIFT_IDS after a live catalog check.
  }
  if (!kinds.has(kind)) return null;
  const upstream = data.common?.msgId ?? data.msgId;
  // Rounded numeric IDs cannot be made stable again; reject rather than deduplicate the wrong gift.
  if (typeof upstream === 'number' && !Number.isSafeInteger(upstream)) return null;
  let handle = '';
  for (const char of user.uniqueId) { if (Buffer.byteLength(handle + char) > 80) break; handle += char; }
  const event = { id: `${kind}:${upstream || randomUUID()}`, kind, uniqueId: handle, name: '@' + handle };
  if (Buffer.byteLength(event.id) > 120) return null;
  const asset = Object.hasOwn(assets, handle.toLowerCase()) && assets[handle.toLowerCase()];
  if (asset) event.avatarAssetId = asset;
  return event;
}
