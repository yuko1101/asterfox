plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.chaquo.python")
}

android {
    namespace = "net.asterfox.app"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    defaultConfig {
        // Specify your own unique Application ID
        // (https://developer.android.com/studio/build/application-id.html).
        applicationId = "net.asterfox.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 28
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        python {
            version "3.8"
        }
        ndk {
            abiFilters += listOf("arm64-v8a", "x86_64")
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    jvmToolchain(21)
}

flutter { source = "../.." }

chaquopy {
    defaultConfig {
        version = "3.11"
        buildPython("/nix/store/gf7b5x6vh2g3bq054lm5pj7zqzfx7vjc-python3-3.11.13/bin/python")
        pip {
            install("yt-dlp")
        }
    }
}
