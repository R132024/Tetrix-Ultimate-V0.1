allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    project.plugins.whenPluginAdded {
        if (this.javaClass.name.startsWith("com.android.build.gradle")) {
            val android = project.extensions.findByName("android")
            if (android != null) {
                try {
                    android.javaClass.getMethod("setCompileSdkVersion", Int::class.java).invoke(android, 36)
                } catch (e: Exception) {}
                try {
                    android.javaClass.getMethod("setCompileSdk", Int::class.java).invoke(android, 36)
                } catch (e: Exception) {}
            }
        }
    }
}
