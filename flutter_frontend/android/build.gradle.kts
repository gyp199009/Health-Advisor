allprojects {
    repositories {
        maven { url = uri("https://maven.aliyun.com/repository/public/") }
        maven { url = uri("https://maven.aliyun.com/repository/spring/")}
        maven { url = uri("https://maven.aliyun.com/repository/google/")}
        maven { url = uri("https://maven.aliyun.com/repository/gradle-plugin/")}
        maven { url = uri("https://maven.aliyun.com/repository/spring-plugin/")}
        maven { url = uri("https://maven.aliyun.com/repository/grails-core/")}
        maven { url = uri("https://maven.aliyun.com/repository/apache-snapshots/")}
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
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
