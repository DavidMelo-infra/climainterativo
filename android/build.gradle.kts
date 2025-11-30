buildscript {
    ext.kotlin_version = '1.9.22' // ✅ ATUALIZADO
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.0") // ✅ ATUALIZADO
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version") // ✅ USANDO VARIÁVEL
        classpath("com.google.gms:google-services:4.4.0") // ✅ ATUALIZADO
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = File("../build")
subprojects {
    project.buildDir = File("${rootProject.buildDir}/${project.name}")
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}