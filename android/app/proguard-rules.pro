# R8 rules for the release build.
#
# Most of this app is Dart, which is AOT compiled and invisible to R8. What
# survives here is plugin glue: Firebase, MLKit (mobile_scanner), and the
# Play Core stubs the Flutter engine references. Flutter's own rules arrive
# through the engine's consumer ProGuard files; only the gaps are listed.

# Crashlytics symbolicates against these. Without them a minified release
# reports line-less frames, which is the one thing crash reporting is for.
-keepattributes SourceFile,LineNumberTable
-keepattributes *Annotation*

# Exception types are matched by name at the Dart/platform boundary; renaming
# them turns a typed platform error into an unrecognised one.
-keep public class * extends java.lang.Exception

# mobile_scanner → MLKit barcode. The model loader resolves these reflectively,
# so R8 cannot see the references and strips them.
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# The Flutter engine references Play Core's deferred-components API even when
# the app never splits. Not shipping it is fine; warning about it is not.
-dontwarn com.google.android.play.core.**
