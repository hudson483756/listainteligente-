# Preservar plugins de Câmera e MLKit (Mobile Scanner)
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class dev.nhancv.mobile_scanner.** { *; }
-dontwarn com.google.mlkit.**