plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // O Flutter Gradle Plugin deve ser aplicado após os plugins Android e Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.mercadosync.mercado_sync"
    
    // Configurado para 37 para atender aos requisitos dos plugins (permission_handler, mobile_scanner, etc.)
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.mercadosync.mercado_sync"
        minSdk = flutter.minSdkVersion
        targetSdk = 35 // Mantido em 35 para garantir estabilidade e comportamento esperado
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Assinatura usando as chaves de debug por enquanto
            signingConfig = signingConfigs.getByName("debug")
            
            // Aponta para o arquivo de regras do ProGuard (evita que a câmera seja bloqueada no build release)
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}