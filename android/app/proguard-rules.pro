# Keep Google Mobile Ads
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep cunning document scanner
-keep class com.cunning.document.scanner.** { *; }
-dontwarn com.cunning.document.scanner.**

# Keep camera related classes
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**

# Keep PDF and printing libraries
-keep class com.google.android.gms.common.** { *; }
-keep class androidx.print.** { *; }

# Keep Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.**

# Keep all model classes (if any)
-keep class * extends java.io.Serializable { *; }

# General Android rules
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Service