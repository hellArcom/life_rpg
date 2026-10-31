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

// Exclude non-free Google Play Core library injected by Flutter Android embedding
configurations.all {
    exclude(group = "com.google.android.play")
}

// Signing config lives in key.properties (never committed).
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

// F-Droid compatibility: Strip Google Play Core classes from DEX and re-sign APK
tasks.register("stripPlayCoreClasses") {
    group = "build"
    description = "Removes com.google.android.play.core classes from release APK DEX files and re-signs"
    doLast {
        val outputDir = layout.buildDirectory.dir("outputs/flutter-apk").get().asFile
        val apkFiles = outputDir.listFiles { it.name.endsWith("-release.apk") }
        
        if (apkFiles == null || apkFiles.isEmpty()) {
            logger.lifecycle("No release APKs found to strip")
            return@doLast
        }
        
        val toolsDir = file("${project.rootDir}/../android/app/fdroid-tools")
        val baksmaliJar = file("${toolsDir}/baksmali.jar")
        val smaliJar = file("${toolsDir}/smali.jar")
        
        if (!baksmaliJar.exists() || !smaliJar.exists()) {
            logger.warn("baksmali/smali JARs not found in ${toolsDir}. Skipping Play Core stripping.")
            return@doLast
        }
        
        val playCoreClasses = listOf(
            "com/google/android/play/core/tasks/OnSuccessListener",
            "com/google/android/play/core/tasks/OnFailureListener",
            "com/google/android/play/core/splitcompat/SplitCompatApplication",
            "com/google/android/play/core/splitinstall/SplitInstallSessionState",
            "com/google/android/play/core/splitinstall/SplitInstallStateUpdatedListener",
            "com/google/android/play/core/splitinstall/SplitInstallManager"
        )
        
        apkFiles.forEach { apkFile ->
            logger.lifecycle("Processing ${apkFile.name}")
            
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
                    val outDir = file("${tempDir}/out/${dexFile.name}")
                    outDir.mkdirs()
                    
                    // Disassemble with baksmali
                    val baksmaliCmd = listOf("java", "-jar", baksmaliJar.absolutePath, 
                        "disassemble", dexFile.absolutePath, "-o", outDir.absolutePath)
                    val baksmaliProc = ProcessBuilder(baksmaliCmd).start()
                    baksmaliProc.waitFor()
                    if (baksmaliProc.exitValue() != 0) {
                        logger.error("baksmali failed")
                        return@forEach
                    }
                    
                    // Remove Play Core class directories
                    playCoreClasses.forEach { className ->
                        val classDir = file("${outDir}/${className}")
                        if (classDir.exists()) {
                            classDir.deleteRecursively()
                        }
                    }
                    
                    // Reassemble with smali
                    val smaliCmd = listOf("java", "-jar", smaliJar.absolutePath, 
                        "assemble", outDir.absolutePath, "-o", "${tempDir}/${dexFile.name}.new")
                    val smaliProc = ProcessBuilder(smaliCmd).start()
                    smaliProc.waitFor()
                    if (smaliProc.exitValue() != 0) {
                        logger.error("smali failed")
                        return@forEach
                    }
                    
                    val newDex = file("${tempDir}/${dexFile.name}.new/classes.dex")
                    if (newDex.exists()) {
                        newDex.renameTo(dexFile)
                    }
                }
                
                // Supprimer l'ancien dossier META-INF (signature invalide après modification des DEX)
                file("${tempDir}/META-INF").deleteRecursively()

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
                
                newApk.renameTo(apkFile)
                
                // Re-signer l'APK avec apksigner
                val storeFileProp = signingProps.getProperty("storeFile")
                val storePasswordProp = signingProps.getProperty("storePassword")
                val keyAliasProp = signingProps.getProperty("keyAlias")
                val keyPasswordProp = signingProps.getProperty("keyPassword") ?: storePasswordProp
                
                if (keystoreFile != null && keystoreFile.exists() && storePasswordProp != null && keyAliasProp != null) {
                    logger.lifecycle("Re-signing stripped APK with apksigner...")
                    val signCmd = listOf(
                        "apksigner", "sign",
                        "--ks", keystoreFile.absolutePath,
                        "--ks-key-alias", keyAliasProp,
                        "--ks-pass", "pass:$storePasswordProp",
                        "--key-pass", "pass:$keyPasswordProp",
                        apkFile.absolutePath
                    )
                    val signProc = ProcessBuilder(signCmd).redirectErrorStream(true).start()
                    val signOutput = signProc.inputStream.bufferedReader().readText()
                    signProc.waitFor()
                    if (signProc.exitValue() != 0) {
                        logger.error("apksigner failed: $signOutput")
                        return@forEach
                    }
                    logger.lifecycle("Successfully re-signed ${apkFile.name}")
                } else {
                    logger.warn("Keystore properties missing. APK remains unsigned!")
                }
                
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