plugins {

    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.lifh.assignum"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.lifh.assignum"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // El keystore de release no está en el repo. Si falta (otra PC, CI), el APK de release se
    // firma con la clave de debug para poder probarlo; no sirve para actualizar una instalación
    // firmada con el keystore oficial.
    val releaseKeystore = file("../assignum-release.jks")

    signingConfigs {
        create("release") {
            storeFile = releaseKeystore
            storePassword = "assignum123"
            keyAlias = "assignum"
            keyPassword = "assignum123"
        }
    }

    buildTypes {
        release {
            signingConfig = if (releaseKeystore.exists()) signingConfigs.getByName("release")
                            else signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies{
    implementation(platform("com.google.firebase:firebase-bom:34.3.0"))
}
