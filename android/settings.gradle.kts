pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // 8.12.1 is a floor, not a preference: package_info_plus 9 raised its
    // minimum AGP to exactly this, and share_plus 13 drags package_info_plus
    // up with it through win32 6. Lowering this again means pinning both
    // packages back down.
    id("com.android.application") version "8.12.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    // Firebase (processes android/app/google-services.json).
    id("com.google.gms.google-services") version "4.4.2" apply false
    // Crashlytics. Also uploads the R8 mapping file on a release build, which is
    // what keeps minified stack traces readable in the console.
    id("com.google.firebase.crashlytics") version "3.0.2" apply false
}

include(":app")
