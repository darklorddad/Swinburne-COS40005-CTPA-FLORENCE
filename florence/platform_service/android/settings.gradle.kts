pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        val localPropertiesFile = file("local.properties")
        if (localPropertiesFile.exists()) {
            localPropertiesFile.inputStream().use { properties.load(it) }
        }

        val flutterSdkPath = properties.getProperty("flutter.sdk")
        if (flutterSdkPath != null) {
            return@run flutterSdkPath
        }

        val envFlutterRoot = System.getenv("FLUTTER_ROOT")
        require(envFlutterRoot != null) { "flutter.sdk not set in local.properties and FLUTTER_ROOT environment variable not set" }
        envFlutterRoot
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
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
    id("com.google.gms.google-services") version "4.4.4" apply false
    id("com.google.firebase.appdistribution") version "5.0.0" apply false
}

include(":app")