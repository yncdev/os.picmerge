import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 업로드 키는 저장소 밖에 둔다. android/key.properties가 없으면 디버그 키로 서명해 누구나 빌드할 수 있다.
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKey = keystorePropertiesFile.exists()
val keystoreProperties = Properties().apply {
    if (hasReleaseKey) keystorePropertiesFile.inputStream().use { load(it) }
}

// 값이 빠지면 AGP의 서명 검증 작업이 생기지 않으므로 여기서 멈춘다. 오류에는 항목 이름만 적는다.
fun keystoreProperty(name: String): String =
    keystoreProperties.getProperty(name) ?: throw GradleException("android/key.properties has no $name")

android {
    namespace = "com.evao.e0.picmerge"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.evao.e0.picmerge"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                // 상대 경로는 android/app 기준이다.
                storeFile = file(keystoreProperty("storeFile"))
                storePassword = keystoreProperty("storePassword")
                keyAlias = keystoreProperty("keyAlias")
                keyPassword = keystoreProperty("keyPassword")
            }
        }
    }

    buildTypes {
        // 기기에서 통합 테스트를 돌려도 설치된 릴리스 앱을 덮어쓰거나 지우지 않는다.
        debug {
            applicationIdSuffix = ".debug"
        }
        release {
            signingConfig = signingConfigs.getByName(if (hasReleaseKey) "release" else "debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // 헤더 스캔·디코딩 시 EXIF 방향, SAF 폴더 작업, 공유용 FileProvider (DESIGN §3.1)
    implementation("androidx.exifinterface:exifinterface:1.4.2")
    implementation("androidx.documentfile:documentfile:1.0.1")
    implementation("androidx.core:core:1.13.1")

    testImplementation("junit:junit:4.13.2")
}
