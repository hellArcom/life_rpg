# Life RPG ProGuard Rules

# Flutter/Dart
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.android.** { *; }
-keep class io.flutter.embedding.engine.** { *; }

# PointyCastle (cryptography)
-keep class org.bouncycastle.** { *; }
-keep class com.github.luben.** { *; }
-keep class de.knippler.** { *; }

# Keep PointyCastle classes used via reflection
-keep class * extends org.bouncycastle.crypto.** { *; }
-keep class * implements org.bouncycastle.crypto.** { *; }

# Hive (local database)
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.** { *; }

# Riverpod (state management)
-keep class com.remi.** { *; }
-keep class com.remi.flutter_riverpod.** { *; }

# flutter_secure_storage
-keep class com.tekartik.sqflite.** { *; }
-keep class net.sqlcipher.** { *; }

# json_serializable / freezed
-keep class **.*$*Json { *; }
-keep class **.*$*Serializer { *; }

# Keep generated code
-keep class **.*_mapper { *; }
-keep class **.*_g { *; }

# Keep annotations
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keepattributes Signature

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep classes with native methods
-keep class * {
    *** nativeMethods;
}

# Don't warn about missing classes
-dontwarn org.bouncycastle.**
-dontwarn com.github.luben.**
-dontwarn de.knippler.**
-dontwarn io.flutter.**
-dontwarn com.remi.**
-dontwarn com.tekartik.**

# Keep model classes
-keep class com.arcom.life_rpg.** { *; }

# Keep Hive boxes
-keep class com.arcom.life_rpg.models.** { *; }

# Socket.IO
-keep class io.socket.** { *; }

# awesome_notifications
-keep class com.awesome.** { *; }

# WorkManager
-keep class androidx.work.** { *; }

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}
