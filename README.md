# Airgap-Utility deployment

##  Introduction

Airgap-Utility tool connects to the GreenLake (GL) marketplace registry and aids in pulling images to the local harbor instance.

This repo consists of the following

- Shell script to deploy a SLES pod in the K3s cluster (CP node)  which acts as the Ansible seed server. We run the ansible plays for this pod

- Ansible plays to deploy the Airgap-Utility pod and to download images from the GL marketplace to the local harbor

**Notes:** 
1. Make sure Harbor SVC External IP is added to your Jumpstation hostfile
2. Create new project in Harbor named 'airgap' with unlimited resources

### Steps to install Airgap-Utility
####   Deploy Ansible seed server 
1.	Download the ansible repo using the following command on any of the K3s master node. git clone https://github.com/davis-jacob/lh-caas-airgap.git

2.	Edit the yaml file and update proxy details for the Ansible SLES pod deployment.
```bash
Update values for https_proxy, http_proxy and no proxy
vim lh-caas-airgap/scripts/sles_pod.yaml
```

3.	Run the script to deploy SLES pod with anisble installed on the K3s master under name space airgap
```bash
cd lh-caas-airgap/scripts
./sles_container.sh
```
#### Deploy Airgap-Utility 
1.	Exec to the Ansible pod to run the rest of the commands
```bash
kubectl get pods -n airgap |grep ansible
ansible-seed-cb6f6995d-5ww2j      1/1     Running   0          21h

kubectl exec -it ansible-seed-cb6f6995d-5ww2j -n airgap – bash
```
2.	Clone the Git repo to the Ansible seed server
```bash
git clone https://github.com/davis-jacob/lh-caas-airgap.git
```
3.	Edit the vault and variable file with SSH password and proxy.  Default vault password is `changeme`
```bash
cd lh-caas-airgap/
ansible-vault edit vault.yml
vim group_vars/common_vars

```
4.	Edit the host file and update the IP for the K3s master node under ‘[k3smaster]’
```bash
vim hosts
[k3smaster]
172.28.0.102    ansible_connection=ssh  ansible_user=root ansible_password="{{ k3s_root_password }}" ansible_ssh_extra_args='-o StrictHostKeyChecking=no'
```

5.	Run the ansible play to deploy the airgap-utility and to pull the images to the local harbor
```bash
ansible-playbook -i hosts -e @vault.yml  airgap-Utility.yaml --ask-vault-pass
```
6.	Once completed make sure 291 repositories are added to the Harbor project.
