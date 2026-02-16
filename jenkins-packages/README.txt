Put these files in this directory for the offline Jenkins install playbook:

1) Jenkins RPM (download from https://get.jenkins.io/redhat-stable/)
   Example:
     jenkins-2.492.3-1.1.noarch.rpm

2) Optional plugins bundle archive from your Artifactory
   Example:
     jenkins-plugins.tar.gz

Then run:
  ansible-playbook -i inventory/<your_inventory> playbooks/install-jenkins-master-offline.yml
