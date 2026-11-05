const SVG_NS = 'http://www.w3.org/2000/svg';

/**
 * 요소를 만든다. 파일 이름 같은 값은 항상 텍스트 노드로 넣는다 (innerHTML을 쓰지 않는다).
 * attrs의 on* 함수는 이벤트 리스너, true/false 값은 불리언 속성, 나머지는 속성 값이다.
 */
export function h(tag, attrs = {}, ...children) {
  const element = document.createElement(tag);
  for (const [key, value] of Object.entries(attrs)) {
    if (key.startsWith('on') && typeof value === 'function') {
      element.addEventListener(key.slice(2).toLowerCase(), value);
    } else if (value === true) {
      element.setAttribute(key, '');
    } else if (value !== false && value != null) {
      element.setAttribute(key, String(value));
    }
  }
  element.append(...children.filter((child) => child != null));
  return element;
}

/** app.html의 SVG 심벌을 가리키는 아이콘. */
export function icon(name) {
  const svg = document.createElementNS(SVG_NS, 'svg');
  svg.setAttribute('class', 'icon');
  svg.setAttribute('aria-hidden', 'true');
  const use = document.createElementNS(SVG_NS, 'use');
  use.setAttribute('href', `#i-${name}`);
  svg.append(use);
  return svg;
}

export const byId = (id) => document.getElementById(id);
