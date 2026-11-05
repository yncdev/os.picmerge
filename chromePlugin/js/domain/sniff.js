const startsWith = (bytes, signature, at = 0) => signature.every((value, i) => bytes[at + i] === value);
const ascii = (text) => [...text].map((c) => c.charCodeAt(0));

/** PDF 머리글은 맨 앞이 아니어도 된다 (규격상 앞쪽 1024바이트 안). */
const PDF_SEARCH_LIMIT = 1024;

/**
 * 파일 앞부분으로 형식을 판별한다. 확장자나 MIME은 믿지 않는다.
 * HEIC/HEIF는 Chrome이 풀 수 없어 null이다 (DESIGN §5.2).
 * @param {Uint8Array} bytes 파일 앞쪽 최소 1024바이트
 * @returns {'jpeg'|'png'|'webp'|'pdf'|null}
 */
export function sniffKind(bytes) {
  if (startsWith(bytes, [0xff, 0xd8, 0xff])) return 'jpeg';
  if (startsWith(bytes, [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])) return 'png';
  if (startsWith(bytes, ascii('RIFF')) && startsWith(bytes, ascii('WEBP'), 8)) return 'webp';
  const marker = ascii('%PDF-');
  const limit = Math.min(bytes.length, PDF_SEARCH_LIMIT) - marker.length;
  for (let i = 0; i <= limit; i++) {
    if (startsWith(bytes, marker, i)) return 'pdf';
  }
  return null;
}

export const SNIFF_LENGTH = PDF_SEARCH_LIMIT;
