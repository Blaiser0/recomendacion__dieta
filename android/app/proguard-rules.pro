# TensorFlow Lite (tflite_flutter): delegado GPU opcional no incluido en el APK.
-dontwarn org.tensorflow.lite.gpu.**
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options

-keep class org.tensorflow.lite.** { *; }
