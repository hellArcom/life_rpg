import com.android.build.gradle.internal.api.ApkVariantOutputImpl
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Signing config lives in key.properties (never committed). Signing is enabled
// only when the keystore file actually exists: on the F-Droid build server
// key.properties is absent so the release build stays unsigned.
val signingProps = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) {
        file.inputStream().use { load(it) }
    }
}
val keystoreFile = if (signingProps.containsKey("storeFile")) {
    file(signingProps.getProperty("storeFile"))
} else {
    null
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

android {
    namespace = "com.arcom.life_rpg"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.arcom.life_rpg"
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystoreFile != null && keystoreFile.exists()) {
            create("release") {
                storeFile = keystoreFile
                storePassword = signingProps.getProperty("storePassword")
                keyAlias = signingProps.getProperty("keyAlias")
                keyPassword = signingProps.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        debug {
            applicationIdSuffix = ".test"
        }
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            if (keystoreFile != null && keystoreFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }

    // ABI split version code scheme: each ABI gets a distinct version code
    // (base*10 + abi). Order: armeabi-v7a=1, arm64-v8a=2, x86_64=3.
    // F-Droid mirrors this with "VercodeOperation: 10 * %c + 1/2/3" in the
    // app metadata so that the client always picks the highest installable ABI.
    applicationVariants.configureEach {
        val variant = this
        variant.outputs.forEach { output ->
            val abiCodes = mapOf("armeabi-v7a" to 1, "arm64-v8a" to 2, "x86_64" to 3)
            val abiCode = abiCodes[output.filters.firstOrNull { it.filterType == "ABI" }?.identifier]
            if (abiCode != null) {
                (output as ApkVariantOutputImpl).versionCodeOverride = variant.versionCode * 10 + abiCode
            }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
