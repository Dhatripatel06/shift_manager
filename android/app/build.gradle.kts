import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.vishrutdonda.vd_shift_manager"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(JvmTarget.JVM_11)
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.vishrutdonda.vd_shift_manager"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // PRODUCTION: Replace these with your actual keystore properties
            // To create a keystore: keytool -genkey -v -keystore ~/shiftly-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias shiftly
            // Set environment variables: SHIFTLY_KEYSTORE_PATH, SHIFTLY_KEYSTORE_PASS, SHIFTLY_KEY_ALIAS, SHIFTLY_KEY_PASS
            val keystorePath = System.getenv("SHIFTLY_KEYSTORE_PATH") ?: "shiftly-release.jks"
            val keystorePassword = System.getenv("SHIFTLY_KEYSTORE_PASS") ?: ""
            val keyAliasName = System.getenv("SHIFTLY_KEY_ALIAS") ?: "shiftly"
            val keyPasswordValue = System.getenv("SHIFTLY_KEY_PASS") ?: ""
            
            if (keystorePassword.isNotEmpty() && keyPasswordValue.isNotEmpty()) {
                storeFile = file(keystorePath)
                storePassword = keystorePassword
                keyAlias = keyAliasName
                keyPassword = keyPasswordValue
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (
                System.getenv("SHIFTLY_KEYSTORE_PASS").isNullOrEmpty() ||
                System.getenv("SHIFTLY_KEY_PASS").isNullOrEmpty()
            ) {
                signingConfigs.getByName("debug")
            } else {
                signingConfigs.getByName("release")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.google.android.play:feature-delivery:2.1.0")
}
