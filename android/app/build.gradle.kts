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

android {
    namespace = "nexus.federated.nexus"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

	lint {
		disable += setOf("EasterEgg", "StopShip")
	}

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "nexus.federated.nexus"
        minSdk = 29
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
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
            signingConfig = signingConfigs.getByName("release")
        }

        debug {
            applicationIdSuffix = ".debug"
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