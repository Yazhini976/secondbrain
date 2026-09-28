# Keep all ML Kit and Google Common classes for text recognition
-keep class com.google.mlkit.** { *; }
-keep interface com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

-keep class * implements com.google.firebase.components.ComponentRegistrar
-keep class * implements com.google.android.datatransport.runtime.backends.BackendFactory

# Flutter and standard plugins
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**
