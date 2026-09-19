import com.android.build.gradle.internal.api.ApkVariantOutputImpl
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.net.URL
import java.nio.file.Files
import java.util.Properties
import java.util.zip.ZipEntry
import java.util.zip.ZipFile
import java.util.zip.ZipOutputStream

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

configurations {
    all {
        exclude(group = "com.google.android.play", module = "core")
    }
}

// F-Droid compatibility: Strip Google Play Core classes from DEX
// These classes are embedded in the Flutter engine and violate F-Droid's non-free policy
tasks.register("stripPlayCoreClasses") {
    group = "build"
    description = "Removes com.google.android.play.core classes from release APK DEX files"
    doLast {
        val outputDir = layout.buildDirectory.dir("outputs/flutter-apk").get().asFile
        val apkFiles = outputDir.listFiles { it.name.endsWith("-release.apk") }
        
        if (apkFiles == null || apkFiles.isEmpty()) {
            logger.lifecycle("No release APKs found to strip")
            return@doLast
        }
        
        // Use pre-bundled baksmali/smali JARs (in android/app/fdroid-tools/)
        // Download standalone JARs from: https://bitbucket.org/JesusFreke/smali/downloads/ (archived)
        // Place baksmali.jar and smali.jar in android/app/fdroid-tools/
        val toolsDir = file("${project.rootDir}/../android/app/fdroid-tools")
        val baksmaliJar = file("${toolsDir}/baksmali.jar")
        val smaliJar = file("${toolsDir}/smali.jar")
        
        if (!baksmaliJar.exists() || !smaliJar.exists()) {
            logger.warn("baksmali/smali JARs not found in ${toolsDir}. Skipping Play Core stripping.")
            logger.warn("Download standalone JARs from https://bitbucket.org/JesusFreke/smali/downloads/ (archived)")
            return@doLast
        }
        
        // Classes to remove (F-Droid flagged classes)
        val playCoreClasses = listOf(
            "com/google/android/play/core/tasks/OnSuccessListener",
            "com/google/android/play/core/tasks/OnFailureListener",
            "com/google/android/play/core/splitcompat/SplitCompatApplication",
            "com/google/android/play/core/splitinstall/SplitInstallSessionState",
            "com/google/android/play/core/splitinstall/SplitInstallStateUpdatedListener",
            "com/google/android/play/core/splitinstall/SplitInstallManager"
        )
        
        apkFiles.forEach { apkFile ->
            logger.lifecycle("Stripping Play Core classes from ${apkFile.name}")
            
            val tempDir = layout.buildDirectory.dir("tmp/strip/${apkFile.name}").get().asFile
            tempDir.mkdirs()
            
            try {
                // Extract APK
                val zipFile = ZipFile(apkFile)
                val entries = zipFile.entries()
                while (entries.hasMoreElements()) {
                    val entry = entries.nextElement()
                    if (!entry.isDirectory) {
                        val outFile = file("${tempDir}/${entry.name}")
                        outFile.parentFile.mkdirs()
                        val inputStream: InputStream = zipFile.getInputStream(entry)
                        val outputStream = outFile.outputStream()
                        try {
                            inputStream.copyTo(outputStream)
                        } finally {
                            inputStream.close()
                            outputStream.close()
                        }
                    }
                }
                zipFile.close()
                
                // Process each DEX file
                val dexFiles = project.fileTree(mapOf("dir" to tempDir, "include" to "classes*.dex")).files
                dexFiles.forEach { dexFile ->
                    logger.lifecycle("Processing ${dexFile.name}")
                    
                    val outDir = file("${tempDir}/out/${dexFile.name}")
                    outDir.mkdirs()
                    
                    // Disassemble with baksmali
                    val baksmaliCmd = listOf("java", "-jar", baksmaliJar.absolutePath, 
                        "disassemble", dexFile.absolutePath, "-o", outDir.absolutePath)
                    val baksmaliProc = ProcessBuilder(baksmaliCmd).start()
                    baksmaliProc.waitFor()
                    if (baksmaliProc.exitValue() != 0) {
                        val error = baksmaliProc.errorStream.bufferedReader().readText()
                        logger.error("baksmali failed: $error")
                        return@doLast
                    }
                    
                    // Remove Play Core class directories
                    playCoreClasses.forEach { className ->
                        val classDir = file("${outDir}/${className}")
                        if (classDir.exists()) {
                            logger.lifecycle("Removing ${className}")
                            classDir.deleteRecursively()
                        }
                    }
                    
                    // Reassemble with smali
                    val smaliCmd = listOf("java", "-jar", smaliJar.absolutePath, 
                        "assemble", outDir.absolutePath, "-o", "${tempDir}/${dexFile.name}.new")
                    val smaliProc = ProcessBuilder(smaliCmd).start()
                    smaliProc.waitFor()
                    if (smaliProc.exitValue() != 0) {
                        val error = smaliProc.errorStream.bufferedReader().readText()
                        logger.error("smali failed: $error")
                        return@doLast
                    }
                    
                    // Replace original DEX
                    val newDex = file("${tempDir}/${dexFile.name}.new/classes.dex")
                    if (newDex.exists()) {
                        newDex.renameTo(dexFile)
                    }
                }
                
                // Repackage APK
                val newApk = file("${outputDir}/${apkFile.name}.stripped")
                val zipOut = ZipOutputStream(newApk.outputStream())
                project.fileTree(mapOf("dir" to tempDir, "include" to "**/*")).files.forEach { file ->
                    if (file.isFile) {
                        val entryName = tempDir.toURI().relativize(file.toURI()).path
                        zipOut.putNextEntry(ZipEntry(entryName))
                        zipOut.write(file.readBytes())
                        zipOut.closeEntry()
                    }
                }
                zipOut.close()
                
                // Replace original APK
                newApk.renameTo(apkFile)
                logger.lifecycle("Successfully stripped ${apkFile.name}")
                
            } finally {
                tempDir.deleteRecursively()
            }
        }
    }
}

// Hook into the build process - use afterEvaluate since assembleRelease is created lazily
afterEvaluate {
    tasks.named("assembleRelease") {
        finalizedBy("stripPlayCoreClasses")
    }
}

flutter {
    source = "../.."
}