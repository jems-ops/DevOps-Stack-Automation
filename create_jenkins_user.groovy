import hudson.security.*
import jenkins.model.*

def jenkins = Jenkins.getInstance()
def realm = jenkins.getSecurityRealm()

// Add admin user
if (realm instanceof HudsonPrivateSecurityRealm) {
    def user = realm.createAccount("jimi", "Jenkins@2025")
    user.setFullName("Jenkins Administrator")
    user.addProperty(new hudson.tasks.Mailer.UserProperty("jimi@jenkins.local"))
    user.save()
    println("User 'jimi' created successfully")
} else {
    println("Security realm is not HudsonPrivateSecurityRealm")
}

jenkins.save()
