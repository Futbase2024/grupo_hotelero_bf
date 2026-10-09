import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Google Services plugin for Firebase
    id("com.google.gms.google-services")
}

// Cargar propiedades del keystore
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.bfstay.app"
    compileSdk = 36  // Android 16 (SDK 36) - requerido por Google Play
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.bfstay.app"
        minSdk = flutter.minSdkVersion
        targetSdk = 36  // Android 16 (SDK 36) - requerido por Google Play (31 ago 2026)
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // El filtro de ABIs se aplica solo en release (ver buildTypes) para que los builds
        // de debug sigan funcionando en emuladores x86_64.
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file("$it") }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    packaging {
        jniLibs {
            // androidx.datastore incluye esta .so precompilada con NDK r20 y Play la marca
            // como riesgo en dispositivos de 16 KB. Solo la usa DataStore multiproceso,
            // que la app no utiliza (R8 elimina todo el código que la carga).
            excludes += "**/libdatastore_shared_counter.so"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // R8: ofuscación + eliminación de código muerto y de recursos no referenciados.
            // R8 full mode es el predeterminado desde AGP 8.x.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // Solo ABIs de dispositivos reales; x86_64 es únicamente para emuladores.
            // clear() es necesario: el plugin de Flutter ya añade armeabi-v7a, arm64-v8a y
            // x86_64 a cada buildType, y con += solo se sumaban. Sin él, las .so x86_64 de
            // CameraX entraban en el AAB sin libflutter.so y Play ofrecía la app a
            // dispositivos x86_64 en los que no arrancaría.
            ndk {
                abiFilters.clear()
                abiFilters += listOf("armeabi-v7a", "arm64-v8a")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase BOM - maneja versiones automáticamente
    implementation(platform("com.google.firebase:firebase-bom:33.7.0"))
    implementation("com.google.firebase:firebase-messaging")

    // AndroidX Core para Edge-to-Edge (WindowCompat, WindowInsetsCompat)
    implementation("androidx.core:core:1.15.0")

    // Desugaring para flutter_local_notifications
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
