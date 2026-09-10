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

    compileOptions {
		isCoreLibraryDesugaringEnabled = true
		sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    defaultConfig {
        applicationId = "nexus.federated.nexus"

		minSdk = 29
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
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
            signingConfig = signingConfigs.getByName("release")
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