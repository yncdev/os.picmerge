// 상단·하단 막대 색과 글꼴 (DESIGN §2.2). 실제로 칠해진 색은 tool/chrome_e2e가 다시 확인한다.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { describe, test } from 'node:test';

import { root } from './i18n_helper.mjs';

const css = readFileSync(join(root, 'css', 'app.css'), 'utf8');

/** :root에 적은 색 변수. var(--x)는 따라가서 풀어 준다. */
function cssVariable(name) {
  const value = css.match(new RegExp(`${name}:\\s*([^;]+);`))?.[1]?.trim();
  assert.ok(value, `${name} is not defined`);
  const reference = value.match(/^var\((--[\w-]+)\)$/);
  return reference ? cssVariable(reference[1]) : value;
}

function ruleBody(selector) {
  const escaped = selector.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const body = css.match(new RegExp(`(?:^|\\n|,\\s*)${escaped}\\s*\\{([^}]*)\\}`))?.[1];
  assert.ok(body !== undefined, `${selector} is not defined`);
  return body;
}

const linear = (channel) => {
  const c = channel / 255;
  return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
};
const luminance = (hex) => {
  const [r, g, b] = [1, 3, 5].map((i) => Number.parseInt(hex.slice(i, i + 2), 16));
  return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b);
};
function contrast(a, b) {
  const [light, dark] = [luminance(a), luminance(b)].sort((x, y) => y - x);
  return (light + 0.05) / (dark + 0.05);
}

const close = (actual, expected, tolerance = 0.01) =>
  assert.ok(Math.abs(actual - expected) <= tolerance, `${actual} is not within ${tolerance} of ${expected}`);

describe('명암비 계산', () => {
  test('알려진 값: 흑백 21:1, 흰색 대 #767676은 약 4.54:1', () => {
    close(contrast('#000000', '#ffffff'), 21);
    close(contrast('#ffffff', '#767676'), 4.54);
  });
});

describe('상단과 하단 막대', () => {
  const bar = cssVariable('--bar-background');
  const pairs = [
    // 기대값은 별도 계산 (WCAG 공식, 8비트 sRGB).
    ['막대의 제목·버튼 글자', cssVariable('--on-bar'), bar, 6.78],
    ['막대의 보조 글자와 비활성 버튼 글자', cssVariable('--on-bar-muted'), bar, 5.4],
    ['막대의 경고 글자', cssVariable('--on-bar-hint'), bar, 5.64],
    ['막대 위 채운 버튼', cssVariable('--primary-dark'), cssVariable('--on-bar'), 6.78],
    ['막대 위 채운 버튼 위에 올렸을 때', cssVariable('--primary-dark'), cssVariable('--tonal'), 5.7],
    ['막대 위 옅은 버튼', cssVariable('--on-tonal'), cssVariable('--tonal'), 7.9],
  ];
  for (const [name, foreground, background, expected] of pairs) {
    test(`${name}: ${foreground} / ${background} ≈ ${expected}:1, 4.5:1 이상`, () => {
      const ratio = contrast(foreground, background);
      close(ratio, expected);
      assert.ok(ratio >= 4.5, String(ratio));
    });
  }
  test('막대 위 옅은 버튼에 올렸을 때도 4.5:1 이상', () => {
    assert.ok(contrast(cssVariable('--on-tonal'), cssVariable('--tonal-hover')) >= 4.5);
  });
  test('막대 색은 진한 주 색상이다', () => {
    assert.equal(bar, '#2257b5');
  });
  test('두 막대가 같은 배경과 글자색을 쓴다', () => {
    for (const selector of ['.topbar', '.save-bar']) {
      assert.match(ruleBody(selector), /background:\s*var\(--bar-background\)/, selector);
      assert.match(ruleBody(selector), /color:\s*var\(--on-bar\)/, selector);
    }
  });
  test('막대 안의 비활성 표시는 투명도로 흐리지 않는다', () => {
    assert.match(ruleBody('.save-bar .button:disabled'), /opacity:\s*1/);
    assert.match(ruleBody('.topbar .icon-button:disabled'), /opacity:\s*1/);
  });
  test("막대 안의 '변경' 글자는 막대 글자색을 쓰고 비활성도 흐리지 않는다", () => {
    assert.match(ruleBody('.bar-link'), /color:\s*var\(--on-bar\)/);
    assert.match(ruleBody('.bar-link:disabled'), /color:\s*var\(--on-bar-muted\)/);
    assert.doesNotMatch(ruleBody('.bar-link:disabled'), /opacity/);
  });
  test('막대 안의 초점 표시가 보인다', () => {
    assert.match(css, /\.topbar :focus-visible,\s*\.save-bar :focus-visible\s*\{\s*outline-color:\s*var\(--on-bar\)/);
  });
});

describe('글꼴', () => {
  test('기본 글꼴 목록의 맨 앞이 한국어 글꼴이 아니다', () => {
    assert.doesNotMatch(cssVariable('--font'), /^'(Malgun Gothic|Apple SD Gothic Neo|Noto Sans KR)'/);
  });
  const stacks = [
    ['ko', 'Malgun Gothic'],
    ['ja', 'Yu Gothic UI'],
    ['zh-CN', 'Microsoft YaHei UI'],
    ['zh-TW', 'Microsoft JhengHei UI'],
    ['th', 'Leelawadee UI'],
  ];
  for (const [lang, font] of stacks) {
    test(`${lang}: ${font}이 맨 앞이다`, () => {
      const body = css.match(new RegExp(`html\\[lang='${lang}'\\]\\s*\\{([^}]*)\\}`))?.[1];
      assert.ok(body, lang);
      assert.match(body, new RegExp(`--font:\\s*'${font}'`));
      assert.match(body, /system-ui, sans-serif/); // 없는 글자는 시스템 글꼴로 넘어간다
    });
  }
});

describe('짧은 창', () => {
  test('패널 안의 내용이 잘리지 않고 스크롤된다', () => {
    assert.match(ruleBody('.panel'), /overflow:\s*hidden auto/);
  });
});

describe('긴 언어', () => {
  test('버튼 글자가 줄을 바꿀 수 있다', () => {
    assert.doesNotMatch(ruleBody('.button'), /white-space:\s*nowrap/);
  });
  test('설정과 버튼 줄은 넘치지 않고 다음 줄로 내려간다', () => {
    assert.match(ruleBody('.settings'), /flex-wrap:\s*wrap/);
    assert.match(ruleBody('.actions'), /flex-wrap:\s*wrap/);
    assert.match(ruleBody('.save-bar'), /flex-wrap:\s*wrap/);
    assert.match(ruleBody('.list-header'), /flex-wrap:\s*wrap/);
    assert.match(ruleBody('.crop-footer'), /flex-wrap:\s*wrap/);
  });
});
