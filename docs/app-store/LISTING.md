# App Store listing

Values to enter in App Store Connect for the iOS app.

**The iOS app has never been compiled or run. Do not submit it until the steps below pass.**

## Before the first upload (Mac required)

1. Build with Xcode 26 or later, which App Store Connect requires. Run the app on an iPhone and pass `flutter test integration_test/native_bridge_test.dart -d <device>`.
2. In Xcode, add `ios/Runner/PrivacyInfo.xcprivacy` to the Runner target's resources, then check the privacy report in the archive.
3. The app is iPhone only (`TARGETED_DEVICE_FAMILY = 1`), so no iPad screenshots are needed.
4. Make the camera and photo permission messages multilingual with `InfoPlist.strings`. They are English only for now.
5. Take real screenshots on iOS. None exist yet, and Android screenshots must not be used here.
6. For EU distribution, provide Digital Services Act trader status in App Store Connect.

Current settings: bundle ID `com.evao.e0.picmerge`, deployment target iOS 15.0.

## App information

- **Name**: Pic Merge
- **Subtitle**: Combine images and PDFs
- **Primary category**: Productivity
- **Secondary category**: Utilities
- **Keywords**: merge,combine,images,photos,pdf,png,scan,screenshots,document,a4,join,collage
- **Support URL**: https://github.com/yncdev/os.picmerge/issues
- **Marketing URL**: https://github.com/yncdev/os.picmerge
- **Privacy policy URL**: https://github.com/yncdev/os.picmerge/blob/master/PRIVACY.md
- **Copyright**: 2026 evao e0
- **Age rating**: answer the current questionnaire in App Information.
- **License agreement**: the App Store default unless a lawyer advises otherwise. The in-app Terms of Use also apply; check them against Apple's minimum terms before using a custom agreement.
- **Icon**: from the app's asset catalog, 1024×1024 with no alpha.

## Screenshots

- **iPhone, required**: at least one at 1179×2556 or 1206×2622, up to 10.
- JPEG or PNG with no alpha. Use generated sample images, not personal photos.

## Promotional text

```
Turn photos, screenshots and PDFs into one PNG or PDF. Your files stay on your device, with no account, ads or analytics.
```

## Description

```
Pic Merge combines the images and PDFs you choose into a single PNG or PDF file, right on your iPhone.

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

Files are saved in the app's own folder, which you can open in the Files app, or in a folder you choose. Files in the app's folder are removed if you delete the app. Results are reduced to fit 20 MB; if one still cannot fit, the save stops and tells you.

Your files stay on your device. Pic Merge has no account, advertising or analytics, and works without a network connection.

The app follows your device language and is available in English, Korean, Japanese, Chinese (Simplified and Traditional), Spanish, French, German, Portuguese, Russian, Vietnamese, Indonesian and Thai.

Pic Merge is open source under the MIT License.
```

## App privacy

- **Data collection**: Data Not Collected. Confirm against Apple's definitions when filling in the form.
- **Tracking**: none.

## Encryption

`ITSAppUsesNonExemptEncryption` is set to `false` in `Info.plist`, because the app does not use encryption of its own.

## Review notes

```
No account or sign-in is needed. All processing happens on the device and the app makes no network requests. To test, tap Choose images, select at least two photos, then tap Save PNG or Save PDF. Saved files appear in the Files app under On My iPhone > Pic Merge.
```
