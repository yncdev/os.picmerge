# Google Play listing

Values to enter in Google Play Console for the Android app.

## Before the first upload

1. Create an upload key outside the repository, and create `android/key.properties` with `storeFile`, `storePassword`, `keyAlias` and `keyPassword`. Never commit either file. Without this file, release builds fall back to the debug key, which Google Play does not accept.
2. Build the upload file: `flutter build appbundle --release`, which creates `build/app/outputs/bundle/release/app-release.aab`.
3. Personal accounts created after November 13, 2023 must run a closed test with at least 12 testers opted in continuously for at least 14 days before applying for production.

Current build: package `com.evao.e0.picmerge`, target API 36 (Google Play requires 36 or later), minimum API 24.

## Store listing

- **App name**: Pic Merge: Images & PDF
- **Short description**: Combine images and PDFs into one PNG or PDF. Your files stay on your device.
- **App icon**: `icon-512.png`
- **Feature graphic**: `feature-1024x500.png`
- **Phone screenshots**: `screenshot-*.png` (1080×1920)
- **Category**: Productivity
- **Contact email**: yncdev@gmail.com
- **Website**: https://github.com/yncdev/os.picmerge
- **Privacy policy**: https://github.com/yncdev/os.picmerge/blob/master/PRIVACY.md

### Full description

```
Pic Merge combines the images and PDFs you choose into a single PNG or PDF file, right on your phone.

Add 2 to 30 items from JPEG, PNG, WebP, HEIC or PDF files, or take a photo. Each PDF page counts as one item. Reorder them, crop each one, and pick your output:

• Paper: A4, A3, A5, B4, B5, Letter, Legal or the images' original size
• Portrait or landscape
• 1, 2, 3, 4, 6, 8 or 9 images per sheet
• Image size: 100%, 50% or 30%
• Margin: 0%, 3%, 5% or 10%
• Color or black and white

Save as PNG: all sheets are joined into one image, with a light gray line between images.
Save as PDF: one page per sheet, or one page per image with Original size.
Share: send the file to any app through the share sheet.

Files are saved to your Download folder, or to a folder you choose. Results are reduced to fit 20 MB; if one still cannot fit, the save stops and tells you.

Your files stay on your device. Pic Merge needs no internet, storage or camera permission, and has no account, advertising or analytics. It works without a network connection.

The app follows your device language and is available in English, Korean, Japanese, Chinese (Simplified and Traditional), Spanish, French, German, Portuguese, Russian, Vietnamese, Indonesian and Thai.

Pic Merge is open source under the MIT License: https://github.com/yncdev/os.picmerge
```

## App content

- **App access**: all functionality is available without special access.
- **Ads**: no ads.
- **Content rating**: complete the questionnaire. The app is a utility with no user-generated sharing inside the app, no violence and no purchases.
- **Target audience**: the publisher chooses. The app is not designed for children.
- **Advertising ID**: not used.
- **Government, financial, health, news**: not applicable.

## Data safety

- **Does the app collect or share any required user data types?** No.
- All processing happens on the device, the release build has no `INTERNET` permission, and Android app backup is off.
- Send feedback only opens the user's own mail app. The user decides whether to send anything, and the developer receives only what the user sends. Confirm the answer in the form's definitions before submitting.

## Permissions

The release build declares only `com.evao.e0.picmerge.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`, added by AndroidX. There are no photo, video, storage or camera permissions to declare.
