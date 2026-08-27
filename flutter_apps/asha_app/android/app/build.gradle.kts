plugins {
id("com.android.application")
id("org.jetbrains.kotlin.android")

// START: FlutterFire Configuration
id("com.google.gms.google-services")
// END: FlutterFire Configuration

id("dev.flutter.flutter-gradle-plugin")
}

kotlin {
    jvmToolchain(21)
}


android {
namespace = "com.example.asha_app"
compileSdk = flutter.compileSdkVersion
ndkVersion = flutter.ndkVersion

compileOptions {
isCoreLibraryDesugaringEnabled = true
sourceCompatibility = JavaVersion.VERSION_21
targetCompatibility = JavaVersion.VERSION_21
}


defaultConfig {
applicationId = "com.example.asha_app"
minSdk = flutter.minSdkVersion
targetSdk = flutter.targetSdkVersion
versionCode = flutter.versionCode
versionName = flutter.versionName
}

buildTypes {
release {
signingConfig = signingConfigs.getByName("debug")
}
}
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}



flutter {
    source = "../.."
}
