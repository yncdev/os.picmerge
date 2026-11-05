import assert from 'node:assert/strict';
import { describe, test } from 'node:test';

import { buildPdf, pdfNumber } from '../js/domain/pdf_writer.js';

// 4×2 픽셀 빨간 JPEG (Pillow로 만든 실제 파일)
const JPEG = Uint8Array.from(
  atob(
    '/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAUDBAQEAwUEBAQFBQUGBwwIBwcHBw8LCwkMEQ8SEhEPERETFhwXExQaFRERGCEYGh0dHx8fExciJCIeJBweHx7/2wBDAQUFBQcGBw4ICA4eFBEUHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh7/wAARCAACAAQDASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwDzWiiivmT+hj//2Q==',
  ),
  (c) => c.charCodeAt(0),
);

const image = (overrides = {}) => ({
  jpeg: JPEG,
  pixelWidth: 4,
  pixelHeight: 2,
  xPt: 0,
  yPt: 272.7449,
  widthPt: 595.2756,
  heightPt: 297.6378,
  ...overrides,
});

const page = (overrides = {}, images = [image()]) => ({
  pageWidthPt: 595.2756,
  pageHeightPt: 841.8898,
  images,
  ...overrides,
});

const latin1 = (bytes) => Buffer.from(bytes).toString('latin1');

/** startxref → xref 표 → 각 객체 위치를 따라가 파일 구조를 직접 확인한다. */
function readXref(bytes) {
  const text = latin1(bytes);
  const startxref = Number(text.match(/startxref\n(\d+)\n%%EOF\n$/)?.[1]);
  assert.equal(text.slice(startxref, startxref + 5), 'xref\n');
  const lines = text.slice(startxref).split('\n');
  const [first, count] = lines[1].split(' ').map(Number);
  assert.equal(first, 0);
  const entries = [];
  // 항목은 정확히 20바이트다 (PDF 규격).
  const tableStart = startxref + `xref\n${lines[1]}\n`.length;
  for (let n = 0; n < count; n++) {
    const entry = text.slice(tableStart + n * 20, tableStart + (n + 1) * 20);
    assert.match(entry, /^\d{10} \d{5} [nf] \n$/, `entry ${n}`);
    entries.push(Number(entry.slice(0, 10)));
  }
  return { text, entries, count };
}

describe('buildPdf 구조', () => {
  test('머리글은 %PDF-1.4, 끝은 %%EOF', () => {
    const text = latin1(buildPdf([page()]));
    assert.ok(text.startsWith('%PDF-1.4\n'));
    assert.ok(text.endsWith('%%EOF\n'));
  });

  test('xref의 모든 위치가 해당 객체의 시작을 가리킨다', () => {
    const { text, entries, count } = readXref(buildPdf([page(), page(), page()]));
    assert.equal(count, 12); // 0번 + Catalog + Pages + 페이지당 3개 × 3
    for (let n = 1; n < count; n++) {
      assert.equal(text.slice(entries[n], entries[n] + `${n} 0 obj\n`.length), `${n} 0 obj\n`, `object ${n}`);
    }
  });

  test('페이지 수, MediaBox, 이미지 배치, JPEG를 그대로 담는다', () => {
    const bytes = buildPdf([page(), page({ pageWidthPt: 841.8898, pageHeightPt: 595.2756 })]);
    const text = latin1(bytes);
    assert.match(text, /\/Count 2/);
    assert.match(text, /\/Kids \[3 0 R 6 0 R\]/);
    assert.match(text, /\/MediaBox \[0 0 595\.2756 841\.8898\]/);
    assert.match(text, /\/MediaBox \[0 0 841\.8898 595\.2756\]/);
    assert.match(text, /q 595\.2756 0 0 297\.6378 0 272\.7449 cm \/Im0 Do Q/);
    assert.match(text, /\/Width 4 \/Height 2 \/ColorSpace \/DeviceRGB \/BitsPerComponent 8 \/Filter \/DCTDecode/);
    assert.match(text, new RegExp(`/Length ${JPEG.length} >>\\nstream\\n`));
    assert.ok(text.includes(latin1(JPEG)), 'JPEG bytes are embedded unchanged');
  });

  test('콘텐츠 스트림 Length가 실제 길이와 같다', () => {
    const text = latin1(buildPdf([page()]));
    const match = text.match(/<< \/Length (\d+) >>\nstream\n(q [^\n]*)\nendstream/);
    assert.equal(Number(match[1]), match[2].length);
  });

  test('잘못된 입력은 오류', () => {
    assert.throws(() => buildPdf([]), RangeError);
    assert.throws(() => buildPdf([page({}, [image({ jpeg: new Uint8Array([1, 2, 3, 4]) })])]), RangeError);
    assert.throws(() => buildPdf([page({}, [image({ pixelWidth: 0 })])]), RangeError);
    assert.throws(() => buildPdf([page({ pageHeightPt: 0 })]), RangeError);
    assert.throws(() => buildPdf([page({}, [])]), RangeError);
    assert.throws(() => buildPdf([page({}, [image(), image({ jpeg: new Uint8Array([1, 2, 3, 4]) })])]), RangeError);
  });

  test('숫자 표기', () => {
    assert.equal(pdfNumber(595.27559), '595.2756');
    assert.equal(pdfNumber(612), '612');
    assert.equal(pdfNumber(0), '0');
    assert.equal(pdfNumber(10.5), '10.5');
    assert.equal(pdfNumber(100), '100');
    assert.throws(() => pdfNumber(NaN), RangeError);
  });
});

describe('한 페이지에 이미지 여러 장', () => {
  // 첫 페이지 3장, 둘째 페이지 1장.
  // 객체: 1 Catalog, 2 Pages, 3 Page, 4 Contents, 5·6·7 이미지, 8 Page, 9 Contents, 10 이미지. 0번까지 11개.
  const places = [
    { xPt: 10, yPt: 400, widthPt: 200, heightPt: 100 },
    { xPt: 300, yPt: 400, widthPt: 200, heightPt: 100 },
    { xPt: 10, yPt: 20, widthPt: 150.5, heightPt: 75.25, pixelWidth: 8, pixelHeight: 4 },
  ];
  const twoPages = () => [page({}, places.map((place) => image(place))), page()];

  test('xref의 모든 위치가 해당 객체의 시작을 가리킨다', () => {
    const { text, entries, count } = readXref(buildPdf(twoPages()));
    assert.equal(count, 11);
    for (let n = 1; n < count; n++) {
      assert.equal(text.slice(entries[n], entries[n] + `${n} 0 obj\n`.length), `${n} 0 obj\n`, `object ${n}`);
    }
  });
  test('페이지가 이미지를 모두 가리키고, 페이지 트리는 페이지만 센다', () => {
    const text = latin1(buildPdf(twoPages()));
    assert.match(text, /\/Count 2/);
    assert.match(text, /\/Kids \[3 0 R 8 0 R\]/);
    assert.match(text, /\/XObject << \/Im0 5 0 R \/Im1 6 0 R \/Im2 7 0 R >>/);
    assert.match(text, /\/XObject << \/Im0 10 0 R >>/);
    assert.equal(text.match(/\/Subtype \/Image/g).length, 4);
    assert.match(text, /\/Width 8 \/Height 4 /);
  });
  test('콘텐츠 스트림은 이미지마다 한 줄이고 Length가 실제 길이와 같다', () => {
    const text = latin1(buildPdf(twoPages()));
    const expected = [
      'q 200 0 0 100 10 400 cm /Im0 Do Q',
      'q 200 0 0 100 300 400 cm /Im1 Do Q',
      'q 150.5 0 0 75.25 10 20 cm /Im2 Do Q',
    ].join('\n');
    assert.ok(text.includes(`<< /Length ${expected.length} >>\nstream\n${expected}\nendstream`));
  });
  test('선이나 사각형 같은 그리기 명령이 없다. 구분선은 PNG에만 있다', () => {
    const text = latin1(buildPdf(twoPages()));
    const streams = [...text.matchAll(/<< \/Length \d+ >>\nstream\n([\s\S]*?)\nendstream/g)].map((match) => match[1]);
    assert.equal(streams.length, 2);
    for (const stream of streams) {
      assert.doesNotMatch(stream, /\b(re|m|l|S|s|f|F|B)\b/, stream);
    }
  });
  test('pdf.js가 페이지별 이미지 수와 자리를 그대로 읽어 낸다', async () => {
    const pdfjs = await import('../vendor/pdfjs/pdf.min.mjs');
    pdfjs.GlobalWorkerOptions.workerSrc = new URL('../vendor/pdfjs/pdf.worker.min.mjs', import.meta.url).href;
    const task = pdfjs.getDocument({ data: buildPdf(twoPages()), isEvalSupported: false, verbosity: 0 });
    try {
      const doc = await task.promise;
      assert.equal(doc.numPages, 2);
      const opsOf = async (number) => {
        const list = await (await doc.getPage(number)).getOperatorList();
        return list.fnArray.map((fn, i) => ({ fn, args: list.argsArray[i] }));
      };
      const first = await opsOf(1);
      assert.equal(first.filter((op) => op.fn === pdfjs.OPS.paintImageXObject).length, 3);
      assert.equal((await opsOf(2)).filter((op) => op.fn === pdfjs.OPS.paintImageXObject).length, 1);
      const transforms = first.filter((op) => op.fn === pdfjs.OPS.transform).map((op) => [...op.args]);
      assert.deepEqual(transforms, [
        [200, 0, 0, 100, 10, 400],
        [200, 0, 0, 100, 300, 400],
        [150.5, 0, 0, 75.25, 10, 20],
      ]);
      // 이미지 말고 그리는 명령이 없다.
      const drawing = [pdfjs.OPS.fill, pdfjs.OPS.stroke, pdfjs.OPS.constructPath, pdfjs.OPS.rectangle];
      assert.equal(first.filter((op) => drawing.includes(op.fn)).length, 0);
    } finally {
      await task.destroy();
    }
  });
});

describe('동봉한 pdf.js로 다시 읽기', () => {
  test('pdf.js가 페이지 수, 크기, 이미지 그리기를 읽어 낸다', async () => {
    const pdfjs = await import('../vendor/pdfjs/pdf.min.mjs');
    pdfjs.GlobalWorkerOptions.workerSrc = new URL('../vendor/pdfjs/pdf.worker.min.mjs', import.meta.url).href;
    const bytes = buildPdf([
      page(),
      page({ pageWidthPt: 841.8898, pageHeightPt: 595.2756 }, [image({ xPt: 123.4, yPt: 0, widthPt: 595.2756, heightPt: 595.2756 })]),
    ]);
    const task = pdfjs.getDocument({ data: bytes, isEvalSupported: false, verbosity: 0 });
    try {
      const doc = await task.promise;
      assert.equal(doc.numPages, 2);

      const first = await doc.getPage(1);
      assert.deepEqual(first.view.map((v) => Number(v.toFixed(4))), [0, 0, 595.2756, 841.8898]);
      const second = await doc.getPage(2);
      assert.deepEqual(second.view.map((v) => Number(v.toFixed(4))), [0, 0, 841.8898, 595.2756]);

      const operators = await first.getOperatorList();
      const names = operators.fnArray.map((fn) => Object.entries(pdfjs.OPS).find(([, value]) => value === fn)?.[0]);
      assert.ok(names.includes('paintImageXObject'), `operators: ${names.join(',')}`);
      assert.ok(names.includes('transform'), `operators: ${names.join(',')}`);
    } finally {
      await task.destroy();
    }
  });
});
