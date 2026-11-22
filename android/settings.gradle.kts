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
    id("com.android.application") version "9.3.1" apply false
    id("org.jetbrains.kotlin.android") version "2.4.10" apply false
}

include(":app")

// Flutter's plugin loader includes dev dependency plugins like integration_test as projects even in
// release builds (where they're never linked in). integration_test lives in the Flutter SDK, which
// is read-only under Nix, and Gradle 9+ refuses to configure a project whose directory isn't writable.
findProject(":integration_test")?.let { project ->
    if (!project.projectDir.canWrite()) {
        val copy = file("../build/integration_test_android")
        copy.deleteRecursively()
        project.projectDir.copyRecursively(copy)
        project.projectDir = copy
    }
}