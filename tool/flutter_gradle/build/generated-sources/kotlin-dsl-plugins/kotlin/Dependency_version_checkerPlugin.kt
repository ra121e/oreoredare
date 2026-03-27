/**
 * Precompiled [dependency_version_checker.gradle.kts][Dependency_version_checker_gradle] script plugin.
 *
 * @see Dependency_version_checker_gradle
 */
public
class Dependency_version_checkerPlugin : org.gradle.api.Plugin<org.gradle.api.Project> {
    override fun apply(target: org.gradle.api.Project) {
        try {
            Class
                .forName("Dependency_version_checker_gradle")
                .getDeclaredConstructor(org.gradle.api.Project::class.java, org.gradle.api.Project::class.java)
                .newInstance(target, target)
        } catch (e: java.lang.reflect.InvocationTargetException) {
            throw e.targetException
        }
    }
}
