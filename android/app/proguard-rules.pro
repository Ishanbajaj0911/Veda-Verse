# google_mlkit_text_recognition references the optional Chinese, Devanagari,
# Japanese and Korean recognisers. VedaVerse only ships the Latin one (used to
# read lab reports and prescriptions offline), so tell R8 not to expect them.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
