import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Activity 1.8 — release signing (requires android/key.properties from Activity 1.7).
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}
fun keystoreProp(name: String): String? =
    keystoreProperties.getProperty(name)?.trim()?.takeIf { it.isNotEmpty() }

val releaseStoreFile = keystoreProp("storeFile")?.let { rootProject.file(it) }
val hasReleaseKeystore = releaseStoreFile?.exists() == true &&
    keystoreProp("storePassword") != null &&
    keystoreProp("keyPassword") != null &&
    keystoreProp("keyAlias") != null

// Activity 1.5 — applicationId (Play Store / device) vs namespace (Kotlin/Java package).
// applicationId: smart.rajasthan.gov.in (official GoR ID)
// namespace: gov.rajasthan.smart — Kotlin cannot use reserved keyword "in" as a package segment.
val smartApplicationId = "smart.rajasthan.gov.in"
val smartNamespace = "gov.rajasthan.smart"

android {
    namespace = "gov.rajasthan.smart"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = smartApplicationId
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // VAPT: minimum Android 10 (API 29) for security patch support.
        minSdk = maxOf(29, flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProp("keyAlias")
                keyPassword = keystoreProp("keyPassword")
                storeFile = releaseStoreFile
                storePassword = keystoreProp("storePassword")
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                // Fallback until Activity 1.7 keystore exists (local dev only).
                signingConfigs.getByName("debug")
            }
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

// VAPT: bundle assetlinks.json in APK; sync from tool/deploy before each build.
// Pass -PSMART_ENV=uat for UAT fingerprints (matches flutter --dart-define=SMART_ENV=uat).
val smartEnv = (project.findProperty("SMART_ENV") as String?)?.lowercase() ?: "prod"
val assetLinksDeployFile = when (smartEnv) {
    "uat", "dev" -> file("../../tool/deploy/assetlinks-uat.json")
    else -> file("../../tool/deploy/assetlinks-prod.json")
}
val assetLinksApkDir = file("src/main/assets/.well-known")

tasks.register<Copy>("syncAssetLinksIntoApk") {
    description = "Copies assetlinks.json into APK assets (VAPT)"
    from(assetLinksDeployFile)
    into(assetLinksApkDir)
    rename { "assetlinks.json" }
    doFirst {
        if (!assetLinksDeployFile.exists()) {
            throw GradleException("Missing ${assetLinksDeployFile.absolutePath}")
        }
    }
}

tasks.named("preBuild") {
    dependsOn("syncAssetLinksIntoApk")
}
