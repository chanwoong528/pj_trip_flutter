import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}


android {
    namespace = "com.moonspace.pj_trip"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    val dotenv = Properties()
    val dotenvFile = project.rootProject.file("../.env")
    if (dotenvFile.exists()) {
        dotenv.load(dotenvFile.inputStream())
    } else {
        throw GradleException("Missing .env file at ${dotenvFile.absolutePath}")
    }


    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.moonspace.pj_trip"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        buildConfigField("String", "NAVER_MAP_CLIENT_KEY", "\"${dotenv.getProperty("NAVER_MAP_CLIENT_KEY", "")}\"")
        buildConfigField("String", "GOOGLE_MAPS_API_KEY_AOS", "\"${dotenv.getProperty("GOOGLE_MAPS_API_KEY_AOS", "")}\"")


        manifestPlaceholders["GOOGLE_MAPS_API_KEY_AOS"] = dotenv.getProperty("GOOGLE_MAPS_API_KEY_AOS", "")
        println("[manifestPlaceholders:]>  $manifestPlaceholders")

    }

    buildFeatures {
        buildConfig = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}




