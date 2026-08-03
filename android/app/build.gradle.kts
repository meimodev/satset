import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // Firebase: must be applied after the Android/Kotlin plugins.
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing. key.properties is gitignored; CI writes it from Codemagic
// secrets. Absent (fresh clone, no keystore) -> release falls back to debug
// signing so `flutter run --release` and local builds still work.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "id.activid.satset"
    // Pinned, not inherited from `flutter.compileSdkVersion`. Both resolve to 36
    // under Flutter 3.41; taking the SDK's value meant a Flutter upgrade could
    // move the API level the release APK is built and validated against without
    // anything in this repo changing. Bump these deliberately.
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "id.activid.satset"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // minSdk stays inherited: plugin manifests merge it up to 29 (ADR: the
        // app is documented Android 10+), and hardcoding 24 here would only
        // disagree with the merged result.
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Patrol native UI testing.
        // NOTE: no `clearPackageData` / ANDROIDX_TEST_ORCHESTRATOR. On MIUI/HyperOS
        // the orchestrator wipes the app's appops before every test, which resets
        // the MIUI background-activity-start grant and re-blocks the instrumented
        // launch (app bounced to launcher, PatrolAppService :8082 never binds).
        // Plain host-run keeps the grant, so the test can foreground. See
        // docs/testing/patrol.md.
        testInstrumentationRunner = "pl.leancode.patrol.PatrolJUnitRunner"
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Signed with the upload keystore when key.properties is present;
            // otherwise fall back to debug signing for local convenience.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

            // R8 only touches the Java/Kotlin side — the Dart half is AOT
            // compiled and untouched — so the win here is the plugin glue and
            // the unused resources that ship with MLKit and Firebase.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}
