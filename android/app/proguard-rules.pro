# Flutter and Dart obfuscation rules
# Keep Flutter-specific code from being obfuscated

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Flutter classes
-keep class io.flutter.** { *; }
-keep interface io.flutter.** { *; }

# Firebase/Cloud Firestore
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Keep GetX dependencies
-keep class com.getx.** { *; }

# Hive database
-keep class com.example.hive.** { *; }

# Google Sign-In
-keep class com.google.android.gms.auth.** { *; }

# Keep R classes
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Remove verbose logging in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
