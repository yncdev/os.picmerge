/** `YYYYMMDDHHMI`. HHMI는 24시간제 시·분이다. [time]은 기기 현지 시각이다 (DESIGN §2.1.4). */
export function fileStamp(time) {
  const two = (value) => String(value).padStart(2, '0');
  return (
    `${String(time.getFullYear()).padStart(4, '0')}${two(time.getMonth() + 1)}${two(time.getDate())}` +
    `${two(time.getHours())}${two(time.getMinutes())}`
  );
}

/**
 * `YYYYMMDDHHMI_연번.확장자` (DESIGN §2.1.4). 연번은 1부터 시작하고 자릿수를 채우지 않으며, 비어 있는 가장 작은 값이다.
 * 이름 전체를 비교하므로 `_1.png`와 `_1.pdf`는 함께 있을 수 있다.
 * 대소문자는 구분하지 않는다. Windows와 FAT 계열 저장소는 대소문자만 다른 이름을 같은 파일로 본다.
 * @param {Iterable<string>} usedNames 이미 쓰인 이름
 */
export function uniqueFileName(time, extension, usedNames) {
  const used = new Set(Array.from(usedNames, (name) => name.toLowerCase()));
  const stamp = fileStamp(time);
  for (let serial = 1; ; serial++) {
    const name = `${stamp}_${serial}.${extension}`;
    if (!used.has(name.toLowerCase())) return name;
  }
}

export const OUTPUT_FORMATS = Object.freeze({
  png: Object.freeze({ code: 'png', extension: 'png', mimeType: 'image/png' }),
  pdf: Object.freeze({ code: 'pdf', extension: 'pdf', mimeType: 'application/pdf' }),
});
