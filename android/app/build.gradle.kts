import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use(keystoreProperties::load)
}

fun secret(name: String): String? {
    return System.getenv(name)?.takeIf { it.isNotBlank() }
        ?: keystoreProperties.getProperty(name)?.takeIf { it.isNotBlank() }
}

val releaseKeystorePath: String? =
    secret("KEYSTORE_PATH")
        ?: secret("KEYSTORE_FILE")
        ?: rootProject.file("upload-keystore.jks").takeIf { it.exists() }?.absolutePath

val hasReleaseSigning: Boolean =
    releaseKeystorePath != null &&
        secret("KEYSTORE_PASSWORD") != null &&
        secret("KEY_ALIAS") != null &&
        secret("KEY_PASSWORD") != null

android {
    namespace = "com.example.ogra"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.ogra"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (releaseKeystorePath != null) {
                storeFile = file(releaseKeystorePath)
            }
            storePassword = secret("KEYSTORE_PASSWORD")
            keyAlias = secret("KEY_ALIAS")
            keyPassword = secret("KEY_PASSWORD")
        }
    }

    flavorDimensions += "env"
    productFlavors {
        create("beta") {
            dimension = "env"
            applicationIdSuffix = ".beta"
            versionNameSuffix = "-beta"
        }

        create("production") {
            dimension = "env"
        }
    }

    buildTypes {
        release {
            signingConfig =
                if (hasReleaseSigning) {
                    signingConfigs.getByName("release")
                } else {
                    signingConfigs.getByName("debug")
                }
        }
    }
}

flutter {
    source = "../.."
}
