plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") 
}

android {
    namespace = "com.example.jangnkangho"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.jangnkangho"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
    aaptOptions {
        noCompress("tflite")
        noCompress("lite")
    }
}

flutter {
    source = "../.."
}
// dependencies 블록을 파일 끝에 추가
dependencies {
    // Import the Firebase BoM (Bill of Materials)
    // 이 버전을 확인하여 최신 버전으로 업데이트하는 것이 좋습니다.
    implementation(platform("com.google.firebase:firebase-bom:34.5.0"))
    // TODO: 사용할 Firebase 제품의 종속성을 추가합니다.
    // When using the BoM, do not specify versions in Firebase dependencies

    // 예시: Firebase Analytics (가장 기본)
    implementation("com.google.firebase:firebase-analytics")
    // 예시: Firebase Authentication
    // implementation("com.google.firebase:firebase-auth-ktx")

    // 예시: Cloud Firestore
    // implementation("com.google.firebase:firebase-firestore-ktx")
}