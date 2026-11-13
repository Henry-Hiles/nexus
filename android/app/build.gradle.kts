import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use {
        keystoreProperties.load(it)
    }
}

fun versionCodeOf(versionName: String): Int {
    val parts = versionName.split("-", limit = 2)
    val (major, minor, patch) = parts[0].split(".").map(String::toInt)
    val preRelease = parts.getOrNull(1)?.let { Regex("\\d+").find(it)?.value?.toInt() ?: 0 } ?: 999
    return major * 100_000_000 + minor * 1_000_000 + patch * 10_000 + preRelease
}

android {
    namespace = "nexus.federated.nexus"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
		isCoreLibraryDesugaringEnabled = true
		sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    defaultConfig {
        applicationId = "nexus.federated.nexus"

		minSdk = 29
        targetSdk = flutter.targetSdkVersion

        versionCode = versionCodeOf(flutter.versionName!!)
        versionName = flutter.versionName

		multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            keyAlias = "key"

            val storePath =
                keystoreProperties["path"]?.toString()
                    ?: System.getenv("KEYSTORE_PATH")

            storeFile = storePath?.let { file(it) }

            keyPassword =
                keystoreProperties["password"]?.toString()
                    ?: System.getenv("KEYSTORE_PASSWORD")

            storePassword =
                keystoreProperties["password"]?.toString()
                    ?: System.getenv("KEYSTORE_PASSWORD")
        }
    }

    buildTypes {
        release {
            // Unsigned without a keystore, e.g. for F-Droid, which signs it itself
            signingConfig = signingConfigs.getByName("release").takeIf { it.storeFile != null }
        }

        debug {
            applicationIdSuffix = ".debug"
        }
    }
}

dependencies {
    implementation("org.unifiedpush.android:embedded-fcm-distributor:3.1.0")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_21
    }
}

flutter {
    source = "../.."
}