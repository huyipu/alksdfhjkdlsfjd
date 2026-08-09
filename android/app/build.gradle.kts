plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ============================================================
// 【包名唯一配置点】以后换皮改包名(applicationId)只改这一行！
// 原生桥接代码包名固定在 com.tlbb.host，与此处无关。
// ============================================================
val appId = "com.tlbb.tlbb_app"

android {
    namespace = appId
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = appId
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android.txt"),
                "proguard-rules.pro"
            )
        }
    }

    packagingOptions {
        exclude("META-INF/versions/9/OSGI-INF/MANIFEST.MF")
    }
}

dependencies {
    // 巨量引擎转化 SDK（远程 Maven 依赖）
    implementation("com.bytedance.ads:AppConvert:2.0.4")
}

flutter {
    source = "../.."
}

afterEvaluate {
    tasks.named("checkReleaseDuplicateClasses").configure {
        enabled = false
    }
    tasks.named("checkDebugDuplicateClasses").configure {
        enabled = false
    }
}
