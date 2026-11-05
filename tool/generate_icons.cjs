// Pic Merge 아이콘 생성기. 도안은 이 파일의 SVG 조각이 원본이다.
//
// 실행 (sharp는 프로젝트 의존성이 아니다):
//   npm install --prefix <임시폴더> sharp
//   NODE_PATH=<임시폴더>/node_modules node tool/generate_icons.cjs
//
// 만드는 것: assets/icon/*.svg·png, Android mipmap, iOS AppIcon, chromePlugin/icons,
// docs/chrome-web-store/promo-440x280.png, docs/play-store/icon-512.png, feature-1024x500.png
//
// 도안: 사과를 베어 무는 펭귄. 얼굴과 사과를 크게 그리고, 배경은 흐릿한 회색 점선이다.
// 이 프로젝트에서 직접 그렸다. Linux Tux나 Apple 로고가 아니다.
const fs = require('fs');
const path = require('path');
const sharp = require('sharp');

const root = path.resolve(__dirname, '..');

const INK = '#1F2733';
const WHITE = '#FFFFFF';
const BEAK = '#F7A326';
const BEAK_DARK = '#DE7E12';
const CHEEK = '#FFB4AE';
const RED_LIGHT = '#F2555C';
const RED = '#E0343C';
const RED_DARK = '#BE1F2A';
const FLESH = '#FFF3D6';
const FLESH_DARK = '#F3D696';
const STEM = '#7A4A22';
const LEAF = '#58B947';
const LEAF_DARK = '#3F9A33';
const BG_TOP = '#F1F2F4';
const BG_BOTTOM = '#E2E4E8';
const BG_SOLID = '#E9EBEE';
const DOT = '#A5ABB4';

const APPLE_OUTLINE =
  'M0,-72 C28,-98 102,-100 106,-16 C110,62 64,104 28,104 C14,104 9,96 0,96 ' +
  'C-9,96 -14,104 -28,104 C-64,104 -110,62 -106,-16 C-102,-100 -28,-98 0,-72 Z';

const defs = `<defs>
  <linearGradient id="bg" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="${BG_TOP}"/>
    <stop offset="1" stop-color="${BG_BOTTOM}"/>
  </linearGradient>
  <radialGradient id="appleFill" cx="0.62" cy="0.32" r="0.85">
    <stop offset="0" stop-color="${RED_LIGHT}"/>
    <stop offset="0.55" stop-color="${RED}"/>
    <stop offset="1" stop-color="${RED_DARK}"/>
  </radialGradient>
  <clipPath id="appleClip"><path d="${APPLE_OUTLINE}"/></clipPath>
  <clipPath id="rounded"><rect width="1024" height="1024" rx="190"/></clipPath>
  <filter id="soft" x="-5%" y="-5%" width="110%" height="110%"><feGaussianBlur stdDeviation="2.6"/></filter>
</defs>`;

/** 흐릿한 회색 점선. 길이 0인 선에 둥근 끝을 주어 점을 만든다. */
const dottedLines = () => {
  let lines = '';
  for (let y = -500; y <= 1500; y += 96) {
    lines += `<line x1="-500" y1="${y}" x2="1500" y2="${y}"/>`;
  }
  return (
    `<g filter="url(#soft)"><g transform="rotate(-24 512 512)" stroke="${DOT}" stroke-width="12" ` +
    `stroke-linecap="round" stroke-dasharray="0 26" opacity="0.7">${lines}</g></g>`
  );
};

const background = `<rect width="1024" height="1024" fill="url(#bg)"/>${dottedLines()}`;

/** 베어 문 자리는 부리가 닿는 왼쪽 위다. 잎과 꼭지가 있는 과일 모양으로 그린다. */
const apple = `<g transform="translate(706,728) rotate(14) scale(2.08)">
  <path d="M1,-70 C1,-84 4,-96 11,-108" fill="none" stroke="${STEM}" stroke-width="9" stroke-linecap="round"/>
  <path d="M9,-88 C20,-114 44,-120 66,-114 C60,-92 36,-78 9,-88 Z" fill="${LEAF}"/>
  <path d="M9,-88 C26,-100 44,-108 66,-114" fill="none" stroke="${LEAF_DARK}" stroke-width="2.5" stroke-linecap="round"/>
  <path d="${APPLE_OUTLINE}" fill="url(#appleFill)"/>
  <g clip-path="url(#appleClip)">
    <circle cx="-92" cy="-52" r="42" fill="${FLESH}"/>
    <circle cx="-56" cy="-74" r="30" fill="${FLESH}"/>
    <circle cx="-104" cy="-14" r="30" fill="${FLESH}"/>
    <path d="M-84,-40 C-74,-46 -66,-54 -60,-64" fill="none" stroke="${FLESH_DARK}" stroke-width="5" stroke-linecap="round"/>
  </g>
  <ellipse cx="50" cy="-34" rx="17" ry="30" transform="rotate(24 50 -34)" fill="#fff" opacity="0.38"/>
</g>`;

/** 얼굴은 사과 쪽으로 기울인다. */
const head = `<g transform="rotate(9 430 410)">
  <ellipse cx="430" cy="408" rx="346" ry="330" fill="${INK}"/>
  <path d="M430,214 C470,146 590,128 660,196 C738,272 716,420 668,512 C620,606 520,668 430,668 C340,668 240,606 192,512 C144,420 122,272 200,196 C270,128 390,146 430,214 Z" fill="${WHITE}"/>
  <ellipse cx="226" cy="462" rx="44" ry="27" fill="${CHEEK}" opacity="0.9"/>
  <ellipse cx="640" cy="432" rx="38" ry="24" fill="${CHEEK}" opacity="0.9"/>
  <ellipse cx="316" cy="362" rx="62" ry="70" fill="${INK}"/>
  <ellipse cx="544" cy="362" rx="62" ry="70" fill="${INK}"/>
  <circle cx="340" cy="334" r="21" fill="#fff"/>
  <circle cx="568" cy="334" r="21" fill="#fff"/>
  <circle cx="296" cy="392" r="9" fill="#fff"/>
  <circle cx="524" cy="392" r="9" fill="#fff"/>
</g>`;

/** 아랫부리는 사과 뒤, 윗부리는 사과 앞에 그려 물고 있는 모습을 만든다. */
const beakLower = `<path d="M372,520 C430,588 500,640 588,664 C600,668 606,654 596,646 C560,610 520,560 470,500 Z" fill="${BEAK_DARK}"/>`;
const beakUpper = `<path d="M344,470 C398,414 490,416 548,464 C586,496 616,538 632,580 C638,596 622,604 610,594 C572,566 526,558 482,556 C424,552 366,532 344,470 Z" fill="${BEAK}"/>
  <path d="M380,486 C424,512 474,524 530,526" fill="none" stroke="${BEAK_DARK}" stroke-width="7" stroke-linecap="round" opacity="0.55"/>`;

/** 1024 칸에 그린 전체 도안 (배경 제외). */
const artwork = `${head}${beakLower}${apple}${beakUpper}`;

const svg = (body) =>
  `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">${defs}${body}</svg>`;

/** iOS용: 네 귀퉁이까지 채운 정사각형. iOS가 모서리를 깎는다. */
const squareSvg = svg(`${background}${artwork}`);

/** Android 구형, Chrome용: 둥근 사각형. */
const roundedSvg = svg(`<g clip-path="url(#rounded)">${background}</g>${artwork}`);

/** 작은 크기(16·32px)용: 점선이 뭉개지므로 빼고 도안을 조금 키운다. */
const smallSvg = svg(
  `<rect width="1024" height="1024" rx="190" fill="${BG_TOP}"/>` +
    `<g transform="translate(512,512) scale(1.05) translate(-503,-520)">${artwork}</g>`,
);

/** Chrome 웹 스토어 128px 아이콘: 그림은 96px이고 네 변에 16px 투명 여백을 둔다. */
const storeIconSvg = svg(
  `<g transform="translate(128,128) scale(0.75)"><g clip-path="url(#rounded)">${background}</g>${artwork}</g>`,
);

/** Chrome 웹 스토어 프로모션 이미지 440×280. 언어별로 만들 수 없어 글자는 이름만 넣는다. */
const promoSvg =
  `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 652" width="1024" height="652">${defs}` +
  `${background}<g transform="translate(36,44) scale(0.56)">${artwork}</g>` +
  `<text x="640" y="352" font-family="Segoe UI, Arial, sans-serif" font-size="92" font-weight="700" fill="${INK}" text-anchor="start">Pic</text>` +
  `<text x="640" y="452" font-family="Segoe UI, Arial, sans-serif" font-size="92" font-weight="700" fill="${INK}" text-anchor="start">Merge</text>` +
  `</svg>`;

/** Google Play 대표 이미지 1024×500. 글자는 이름만 넣는다. */
const featureSvg =
  `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 500" width="1024" height="500">${defs}` +
  `${background}<g transform="translate(70,24) scale(0.44)">${artwork}</g>` +
  `<text x="535" y="280" font-family="Segoe UI, Arial, sans-serif" font-size="90" font-weight="700" fill="${INK}" text-anchor="start">Pic Merge</text>` +
  `</svg>`;

/** Android 적응형 아이콘 뒷면: 점선 배경. */
const backgroundSvg = svg(background);

/** Android 적응형 아이콘 앞면: 108dp 중 지름 66dp 안전 영역에 들어가게 줄인다. */
const foregroundSvg = svg(`<g transform="translate(512,512) scale(0.64) translate(-500,-500)">${artwork}</g>`);

async function png(source, size, file, {flatten = false} = {}) {
  fs.mkdirSync(path.dirname(file), {recursive: true});
  let image = sharp(Buffer.from(source), {density: 300}).resize(size, size);
  if (flatten) image = image.flatten({background: BG_SOLID}).removeAlpha();
  await image.png({compressionLevel: 9}).toFile(file);
}

async function main() {
  const iconDir = path.join(root, 'assets/icon');
  fs.mkdirSync(iconDir, {recursive: true});
  fs.writeFileSync(path.join(iconDir, 'pic_merge.svg'), squareSvg);
  fs.writeFileSync(path.join(iconDir, 'pic_merge_small.svg'), smallSvg);
  fs.writeFileSync(path.join(iconDir, 'pic_merge_foreground.svg'), foregroundSvg);
  fs.writeFileSync(path.join(iconDir, 'pic_merge_background.svg'), backgroundSvg);
  await png(squareSvg, 1024, path.join(iconDir, 'pic_merge_1024.png'), {flatten: true});
  await png(squareSvg, 512, path.join(iconDir, 'pic_merge_store_512.png'), {flatten: true});

  // Android
  const res = path.join(root, 'android/app/src/main/res');
  const densities = {mdpi: 48, hdpi: 72, xhdpi: 96, xxhdpi: 144, xxxhdpi: 192};
  for (const [density, size] of Object.entries(densities)) {
    const layerSize = Math.round((size * 108) / 48);
    await png(roundedSvg, size, path.join(res, `mipmap-${density}/ic_launcher.png`));
    await png(foregroundSvg, layerSize, path.join(res, `mipmap-${density}/ic_launcher_foreground.png`));
    await png(backgroundSvg, layerSize, path.join(res, `mipmap-${density}/ic_launcher_background.png`), {flatten: true});
  }
  fs.mkdirSync(path.join(res, 'mipmap-anydpi-v26'), {recursive: true});
  fs.writeFileSync(
    path.join(res, 'mipmap-anydpi-v26/ic_launcher.xml'),
    `<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
`,
  );

  // iOS: Contents.json에 적힌 이름과 크기를 그대로 쓴다. App Store 아이콘은 알파가 없어야 한다.
  const appIcon = path.join(root, 'ios/Runner/Assets.xcassets/AppIcon.appiconset');
  if (fs.existsSync(path.join(appIcon, 'Contents.json'))) {
    const contents = JSON.parse(fs.readFileSync(path.join(appIcon, 'Contents.json'), 'utf8'));
    for (const entry of contents.images) {
      if (!entry.filename) continue;
      const px = Math.round(parseFloat(entry.size) * parseFloat(entry.scale));
      await png(squareSvg, px, path.join(appIcon, entry.filename), {flatten: true});
    }
  }

  // Chrome
  const chrome = path.join(root, 'chromePlugin/icons');
  await png(smallSvg, 16, path.join(chrome, 'icon16.png'));
  await png(smallSvg, 32, path.join(chrome, 'icon32.png'));
  await png(roundedSvg, 48, path.join(chrome, 'icon48.png'));
  await png(storeIconSvg, 128, path.join(chrome, 'icon128.png'));

  // Chrome 웹 스토어 등록 자료
  const store = path.join(root, 'docs/chrome-web-store');
  fs.mkdirSync(store, {recursive: true});
  await sharp(Buffer.from(promoSvg), {density: 150})
    .resize(440, 280)
    .flatten({background: BG_SOLID})
    .removeAlpha()
    .png({compressionLevel: 9})
    .toFile(path.join(store, 'promo-440x280.png'));

  // Google Play 등록 자료. 아이콘은 32비트 PNG, 대표 이미지는 알파 없는 24비트 PNG다.
  const play = path.join(root, 'docs/play-store');
  fs.mkdirSync(play, {recursive: true});
  await sharp(Buffer.from(squareSvg), {density: 150})
    .resize(512, 512)
    .flatten({background: BG_SOLID})
    .ensureAlpha(1)
    .png({compressionLevel: 9})
    .toFile(path.join(play, 'icon-512.png'));
  await sharp(Buffer.from(featureSvg), {density: 150})
    .resize(1024, 500)
    .flatten({background: BG_SOLID})
    .removeAlpha()
    .png({compressionLevel: 9})
    .toFile(path.join(play, 'feature-1024x500.png'));

  console.log('done');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
