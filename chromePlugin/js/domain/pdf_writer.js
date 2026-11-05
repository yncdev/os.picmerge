// 이미지 페이지만 있는 작은 PDF 생성기. JPEG는 다시 인코딩하지 않고 그대로(DCTDecode) 넣는다.
// 객체 번호: 1 Catalog, 2 Pages, 그다음 페이지마다 Page, Contents, 그 페이지의 Image XObject들 순서다.

const encoder = new TextEncoder();
const ascii = (text) => encoder.encode(text);

/** 소수점 넷째 자리까지, 뒤쪽 0을 뺀 PDF 숫자. */
export function pdfNumber(value) {
  if (!Number.isFinite(value)) throw new RangeError(`not a finite number: ${value}`);
  const text = value.toFixed(4);
  return text.includes('.') ? text.replace(/\.?0+$/, '') : text;
}

function assertPage(page, index) {
  if (!(page.pageWidthPt > 0) || !(page.pageHeightPt > 0)) throw new RangeError(`page ${index}: page size`);
  if (!page.images?.length) throw new RangeError(`page ${index}: no images`);
  page.images.forEach(({ jpeg, pixelWidth, pixelHeight }, i) => {
    const isJpeg = jpeg instanceof Uint8Array && jpeg.length > 3 && jpeg[0] === 0xff && jpeg[1] === 0xd8;
    if (!isJpeg) throw new RangeError(`page ${index} image ${i}: not JPEG data`);
    if (!(pixelWidth > 0) || !(pixelHeight > 0)) throw new RangeError(`page ${index} image ${i}: pixel size`);
  });
}

/**
 * @param {{
 *   pageWidthPt: number, pageHeightPt: number,
 *   images: {
 *     jpeg: Uint8Array, pixelWidth: number, pixelHeight: number,
 *     xPt: number, yPt: number, widthPt: number, heightPt: number,
 *   }[],
 * }[]} pages 페이지마다 이미지가 하나 이상이다.
 * @returns {Uint8Array}
 */
export function buildPdf(pages) {
  if (!pages.length) throw new RangeError('pages must not be empty');
  pages.forEach(assertPage);

  const chunks = [];
  const offsets = []; // offsets[n]은 객체 n의 시작 바이트 위치
  let position = 0;
  const push = (bytes) => {
    chunks.push(bytes);
    position += bytes.length;
  };
  const pushObject = (number, body) => {
    offsets[number] = position;
    push(ascii(`${number} 0 obj\n${body}\nendobj\n`));
  };

  // 두 번째 줄의 바이너리 주석은 파일이 이진임을 전송 도구에 알린다 (PDF 규격 권장).
  push(ascii('%PDF-1.4\n'));
  push(new Uint8Array([0x25, 0xe2, 0xe3, 0xcf, 0xd3, 0x0a]));

  let nextObject = 3;
  const numbered = pages.map((page) => {
    const pageObject = nextObject;
    nextObject += 2 + page.images.length;
    return {
      page,
      pageObject,
      contentObject: pageObject + 1,
      imageObjects: page.images.map((_, i) => pageObject + 2 + i),
    };
  });
  const objectCount = nextObject; // 0번 자유 객체 포함

  pushObject(1, '<< /Type /Catalog /Pages 2 0 R >>');
  const kids = numbered.map(({ pageObject }) => `${pageObject} 0 R`).join(' ');
  pushObject(2, `<< /Type /Pages /Count ${pages.length} /Kids [${kids}] >>`);

  for (const { page, pageObject, contentObject, imageObjects } of numbered) {
    const xObjects = imageObjects.map((object, i) => `/Im${i} ${object} 0 R`).join(' ');
    pushObject(
      pageObject,
      `<< /Type /Page /Parent 2 0 R` +
        ` /MediaBox [0 0 ${pdfNumber(page.pageWidthPt)} ${pdfNumber(page.pageHeightPt)}]` +
        ` /Resources << /XObject << ${xObjects} >> >>` +
        ` /Contents ${contentObject} 0 R >>`,
    );

    const content = page.images
      .map(
        (image, i) =>
          `q ${pdfNumber(image.widthPt)} 0 0 ${pdfNumber(image.heightPt)}` +
          ` ${pdfNumber(image.xPt)} ${pdfNumber(image.yPt)} cm /Im${i} Do Q`,
      )
      .join('\n');
    pushObject(contentObject, `<< /Length ${content.length} >>\nstream\n${content}\nendstream`);

    page.images.forEach((image, i) => {
      const imageObject = imageObjects[i];
      offsets[imageObject] = position;
      push(
        ascii(
          `${imageObject} 0 obj\n<< /Type /XObject /Subtype /Image` +
            ` /Width ${image.pixelWidth} /Height ${image.pixelHeight}` +
            ` /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode` +
            ` /Length ${image.jpeg.length} >>\nstream\n`,
        ),
      );
      push(image.jpeg);
      push(ascii('\nendstream\nendobj\n'));
    });
  }

  const xrefPosition = position;
  const entries = ['0000000000 65535 f \n'];
  for (let n = 1; n < objectCount; n++) {
    entries.push(`${String(offsets[n]).padStart(10, '0')} 00000 n \n`);
  }
  push(
    ascii(
      `xref\n0 ${objectCount}\n${entries.join('')}` +
        `trailer\n<< /Size ${objectCount} /Root 1 0 R >>\n` +
        `startxref\n${xrefPosition}\n%%EOF\n`,
    ),
  );

  const output = new Uint8Array(position);
  let at = 0;
  for (const chunk of chunks) {
    output.set(chunk, at);
    at += chunk.length;
  }
  return output;
}
