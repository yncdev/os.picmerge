// 의존성 없는 PNG 인코더·디코더. 시험 이미지를 만들고 결과 파일을 Chrome과 무관하게 픽셀 단위로 읽는다.
import { crc32, deflateSync, inflateSync } from 'node:zlib';

const SIGNATURE = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);

function chunk(type, data) {
  const out = Buffer.alloc(12 + data.length);
  out.writeUInt32BE(data.length, 0);
  out.write(type, 4, 'latin1');
  data.copy(out, 8);
  out.writeUInt32BE(crc32(out.subarray(4, 8 + data.length)), 8 + data.length);
  return out;
}

/** RGBA 8비트. [fill]은 (x, y) → [r, g, b, a]다. */
export function encodePng(width, height, fill, { level = 6 } = {}) {
  const raw = Buffer.alloc((width * 4 + 1) * height);
  let at = 0;
  for (let y = 0; y < height; y++) {
    raw[at++] = 0; // 필터 없음
    for (let x = 0; x < width; x++) {
      const [r, g, b, a = 255] = fill(x, y);
      raw[at++] = r;
      raw[at++] = g;
      raw[at++] = b;
      raw[at++] = a;
    }
  }
  return encodeRaw(width, height, raw, level);
}

/** 이미 만든 필터 포함 RGBA 바이트로 PNG를 만든다. 큰 잡음 이미지용이다. */
export function encodeRaw(width, height, raw, level = 6) {
  const header = Buffer.alloc(13);
  header.writeUInt32BE(width, 0);
  header.writeUInt32BE(height, 4);
  header[8] = 8; // 비트 깊이
  header[9] = 6; // RGBA
  return Buffer.concat([
    SIGNATURE,
    chunk('IHDR', header),
    chunk('IDAT', deflateSync(raw, { level })),
    chunk('IEND', Buffer.alloc(0)),
  ]);
}

/** 디코딩한 이미지를 RGB 8비트로 저장한다. 투명한 픽셀이 있으면 거부한다. 스토어는 알파 없는 PNG를 요구한다. */
export function encodeRgb(image) {
  const { width, height } = image;
  const raw = Buffer.alloc((width * 3 + 1) * height);
  let at = 0;
  for (let y = 0; y < height; y++) {
    raw[at++] = 0; // 필터 없음
    for (let x = 0; x < width; x++) {
      const [r, g, b, a] = pixel(image, x, y);
      if (a !== 255) throw new Error(`pixel ${x},${y} is not opaque`);
      raw[at++] = r;
      raw[at++] = g;
      raw[at++] = b;
    }
  }
  const header = Buffer.alloc(13);
  header.writeUInt32BE(width, 0);
  header.writeUInt32BE(height, 4);
  header[8] = 8; // 비트 깊이
  header[9] = 2; // RGB
  return Buffer.concat([SIGNATURE, chunk('IHDR', header), chunk('IDAT', deflateSync(raw, { level: 9 })), chunk('IEND', Buffer.alloc(0))]);
}

const paeth = (a, b, c) => {
  const p = a + b - c;
  const pa = Math.abs(p - a);
  const pb = Math.abs(p - b);
  const pc = Math.abs(p - c);
  if (pa <= pb && pa <= pc) return a;
  return pb <= pc ? b : c;
};

/** @returns {{width:number,height:number,colorType:number,channels:number,data:Uint8Array}} */
export function decodePng(bytes) {
  if (!bytes.subarray(0, 8).equals(SIGNATURE)) throw new Error('not a PNG file');
  let width = 0;
  let height = 0;
  let depth = 0;
  let colorType = 0;
  let interlace = 0;
  const idat = [];
  let at = 8;
  while (at < bytes.length) {
    const length = bytes.readUInt32BE(at);
    const type = bytes.toString('latin1', at + 4, at + 8);
    const data = bytes.subarray(at + 8, at + 8 + length);
    const stored = bytes.readUInt32BE(at + 8 + length);
    if (crc32(bytes.subarray(at + 4, at + 8 + length)) !== stored) throw new Error(`bad CRC in ${type}`);
    if (type === 'IHDR') {
      width = data.readUInt32BE(0);
      height = data.readUInt32BE(4);
      depth = data[8];
      colorType = data[9];
      interlace = data[12];
    } else if (type === 'IDAT') {
      idat.push(data);
    }
    at += 12 + length;
  }
  const channelsByType = { 0: 1, 2: 3, 4: 2, 6: 4 };
  const channels = channelsByType[colorType];
  if (depth !== 8 || !channels || interlace !== 0) throw new Error(`unsupported PNG: depth ${depth}, type ${colorType}, interlace ${interlace}`);

  const raw = inflateSync(Buffer.concat(idat), { maxOutputLength: 2 ** 31 - 1 });
  const stride = width * channels;
  if (raw.length !== (stride + 1) * height) throw new Error(`bad PNG data length ${raw.length}`);
  const out = new Uint8Array(stride * height);
  for (let y = 0; y < height; y++) {
    const rowStart = y * (stride + 1) + 1;
    const filter = raw[rowStart - 1];
    const outStart = y * stride;
    for (let i = 0; i < stride; i++) {
      const left = i >= channels ? out[outStart + i - channels] : 0;
      const up = y > 0 ? out[outStart + i - stride] : 0;
      const upLeft = y > 0 && i >= channels ? out[outStart + i - stride - channels] : 0;
      let predictor = 0;
      if (filter === 1) predictor = left;
      else if (filter === 2) predictor = up;
      else if (filter === 3) predictor = (left + up) >> 1;
      else if (filter === 4) predictor = paeth(left, up, upLeft);
      else if (filter !== 0) throw new Error(`bad PNG filter ${filter}`);
      out[outStart + i] = (raw[rowStart + i] + predictor) & 0xff;
    }
  }
  return { width, height, colorType, channels, data: out };
}

/** [r, g, b, a]. 알파가 없는 형식은 255다. */
export function pixel(image, x, y) {
  if (x < 0 || y < 0 || x >= image.width || y >= image.height) throw new RangeError(`pixel ${x},${y} outside ${image.width}x${image.height}`);
  const at = (y * image.width + x) * image.channels;
  const { data, colorType } = image;
  if (colorType === 6) return [data[at], data[at + 1], data[at + 2], data[at + 3]];
  if (colorType === 2) return [data[at], data[at + 1], data[at + 2], 255];
  if (colorType === 4) return [data[at], data[at], data[at], data[at + 1]];
  return [data[at], data[at], data[at], 255];
}

const hex = (value) => value.toString(16).padStart(2, '0');
const colorKey = ([r, g, b, a]) => (a === 0 ? 'transparent' : `#${hex(r)}${hex(g)}${hex(b)}${a === 255 ? '' : hex(a)}`);

/**
 * 한 줄을 따라가며 같은 색이 이어지는 구간을 돌려준다.
 * @param {'row'|'column'} axis
 * @returns {[string, number, number][]} [색, 시작, 끝(미포함)]
 */
export function runsAlong(image, axis, position) {
  const length = axis === 'row' ? image.width : image.height;
  const runs = [];
  for (let i = 0; i < length; i++) {
    const key = colorKey(axis === 'row' ? pixel(image, i, position) : pixel(image, position, i));
    const last = runs.at(-1);
    if (last && last[0] === key) last[2] = i + 1;
    else runs.push([key, i, i + 1]);
  }
  return runs;
}
