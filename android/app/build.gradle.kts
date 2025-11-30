plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

def localProperties = new Properties()
def localPropertiesFile = rootProject.file('local.properties')
if (localPropertiesFile.exists()) {
    localPropertiesFile.withReader('UTF-8') { reader ->
        localProperties.load(reader)
    }
}

def flutterVersionCode = localProperties.getProperty('flutter.versionCode')
if (flutterVersionCode == null) {
    flutterVersionCode = '1'
}

def flutterVersionName = localProperties.getProperty('flutter.versionName')
if (flutterVersionName == null) {
    flutterVersionName = '1.0'
}

android {
    namespace = "com.climainterativo.app"
    compileSdk = 34
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    sourceSets {
        main.java.srcDirs += 'src/main/kotlin'
    }

    defaultConfig {
        applicationId = "com.climainterativo.app"
        minSdk = 21 // ✅ DEFINIDO PARA COMPATIBILIDADE COM FIREBASE
        targetSdk = 34
        versionCode = flutterVersionCode.toInteger()
        versionName = flutterVersionName
        
        // ✅ CONFIGURAÇÕES PARA ARQUITETURAS
        ndk {
            abiFilters 'arm64-v8a', 'x86_64'
        }
        
        // ✅ CONFIGURAÇÕES PARA FIREBASE E GOOGLE SIGN-IN
        manifestPlaceholders["appAuthRedirectScheme"] = "com.climainterativo.app"
        
        // ✅ MULTIDEX PARA FIREBASE
        multiDexEnabled true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            // ✅ OTIMIZAÇÕES PARA RELEASE
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
            
            // ✅ CONFIGURAÇÃO ESPECÍFICA PARA ARM64 NO RELEASE
            ndk {
                abiFilters 'arm64-v8a'
            }
        }
        debug {
            debuggable true
            // ✅ PARA DEBUG, MANTÉM TODAS AS ARCHITECTURES
            ndk {
                abiFilters 'arm64-v8a', 'x86_64', 'armeabi-v7a'
            }
        }
    }

    // ✅ CONFIGURAÇÃO PARA NOTIFICAÇÕES
    lintOptions {
        disable 'InvalidPackage'
        checkReleaseBuilds false
    }
    
    // ✅ CONFIGURAÇÕES ADICIONAIS PARA FIREBASE
    packagingOptions {
        resources {
            excludes += ['/META-INF/**']
        }
    }
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:32.8.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.android.gms:play-services-auth:21.0.0")
    
    // ✅ DEPENDÊNCIAS PARA NOTIFICAÇÕES E COMPATIBILIDADE
    implementation 'androidx.core:core:1.12.0'
    implementation 'androidx.core:core-ktx:1.12.0'
    implementation 'androidx.work:work-runtime:2.9.0'
    implementation 'androidx.work:work-runtime-ktx:2.9.0'
    implementation 'androidx.multidex:multidex:2.0.1'
    implementation 'androidx.appcompat:appcompat:1.6.1'
}

flutter {
    source = "../.."
}