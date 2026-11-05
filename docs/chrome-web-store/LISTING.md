# Chrome Web Store listing

Values to enter in the Chrome Web Store Developer Dashboard for the extension in `chromePlugin/`.

## Package

Build the upload file from the repository root:

```bash
node tool/package_chrome.mjs
```

It creates `build/chrome-web-store/pic-merge-<version>.zip` with `manifest.json` at the top level and without tests or the README.

## Store listing tab

- **Name and summary**: come from `manifest.json` and `_locales/`, so they are not typed in the dashboard.
- **Category**: Productivity, Tools
- **Language**: English, plus the Korean description below
- **Store icon**: `chromePlugin/icons/icon128.png`. It is inside the package; upload it too if the dashboard asks
- **Screenshots**: `screenshot-1-main.png`, `screenshot-2-crop.png`, `screenshot-3-history.png` (1280×800)
- **Small promo tile**: `promo-440x280.png`
- **Homepage URL**: https://github.com/yncdev/os.picmerge
- **Support URL**: https://github.com/yncdev/os.picmerge/issues
- **Mature content**: off

### Detailed description (English)

```
Pic Merge combines the images and PDFs you choose into a single PNG or PDF file, right in your browser.

Add 2 to 30 items from JPEG, PNG, WebP or PDF files. Each PDF page counts as one item. Reorder them, crop each one, and pick your output:

• Paper: A4, A3, A5, B4, B5, Letter, Legal or the images' original size
• Portrait or landscape
• 1, 2, 3, 4, 6, 8 or 9 images per sheet
• Image size: 100%, 50% or 30%
• Margin: 0%, 3%, 5% or 10%
• Color or grayscale

Save as PNG: all sheets are joined into one image, with a light gray line between images.
Save as PDF: one page per sheet, or one page per image with Original size.
Share: use your system's share window where supported, copy the PNG, or download the file and attach it to an email yourself.

Files go to your browser's download folder, or to a folder you choose. Results are reduced to fit 20 MB; if one still cannot fit, the save stops and tells you.

Your files stay on your computer. Pic Merge declares no permissions, loads no remote code and has no account, advertising or analytics. Processing works without a network connection.

The interface follows your browser language and is available in English, Korean, Japanese, Chinese (Simplified and Traditional), Spanish, French, German, Portuguese, Russian, Vietnamese, Indonesian and Thai.

Pic Merge is open source under the MIT License: https://github.com/yncdev/os.picmerge

Not supported: HEIC/HEIF images and password-protected PDFs.
```

### Detailed description (Korean)

```
Pic Merge는 고른 이미지와 PDF를 브라우저 안에서 하나의 PNG나 PDF 파일로 합칩니다.

JPEG, PNG, WebP, PDF 파일에서 항목을 2~30개 담습니다. PDF는 페이지마다 항목 1개입니다. 순서를 바꾸고, 항목별로 영역을 자르고, 출력 방식을 고르세요.

• 용지: A4, A3, A5, B4, B5, Letter, Legal, 이미지 원본 크기
• 세로 또는 가로
• 용지당 이미지 1, 2, 3, 4, 6, 8, 9개
• 이미지 크기: 100%, 50%, 30%
• 여백: 0%, 3%, 5%, 10%
• 컬러 또는 흑백

PNG 저장: 모든 용지를 한 장으로 잇고, 이미지 사이에 옅은 회색 선을 넣습니다.
PDF 저장: 용지 한 장이 한 페이지입니다. '원본 크기'는 이미지 하나가 한 페이지입니다.
공유: 지원하는 환경에서 OS 공유 창을 쓰거나, PNG를 복사하거나, 파일을 내려받아 메일에 직접 첨부할 수 있습니다.

파일은 브라우저의 다운로드 폴더나 직접 고른 폴더에 저장됩니다. 결과는 20MB에 맞게 줄이고, 그래도 넘으면 저장을 멈추고 안내합니다.

파일은 내 컴퓨터 밖으로 나가지 않습니다. 권한을 선언하지 않고, 원격 코드를 불러오지 않으며, 계정, 광고, 분석 도구가 없습니다. 네트워크 연결 없이 처리합니다.

화면은 브라우저 언어를 따르며 한국어, 영어, 일본어, 중국어(간체, 번체), 스페인어, 프랑스어, 독일어, 포르투갈어, 러시아어, 베트남어, 인도네시아어, 태국어를 지원합니다.

Pic Merge는 MIT License 오픈소스입니다: https://github.com/yncdev/os.picmerge

지원하지 않는 입력: HEIC/HEIF 이미지, 암호가 걸린 PDF
```

## Privacy practices tab

- **Single purpose**: Combine images and PDFs that the user selects into a single PNG or PDF file on the user's computer.
- **Permission justification**: none needed. `permissions` and `host_permissions` are empty.
- **Remote code**: No, I am not using remote code. pdf.js is bundled in the package with its worker, WebAssembly, fonts and CMaps. Its code is minified as published and not obfuscated.
- **Data usage**: leave every data type unchecked. Files and history stay on the user's computer and are never sent anywhere.
- **Certifications**: the publisher reads and certifies these personally.
- **Privacy policy URL**: https://github.com/yncdev/os.picmerge/blob/master/PRIVACY.md

## Distribution tab

- **Visibility**: choose Public or Unlisted when submitting.
- **Regions**: all regions by default.
