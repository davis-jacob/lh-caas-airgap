# Airgap-Utility deployment

##  Introduction

Airgap-Utility tool connects to the GreenLake (GL) marketplace registry and aids in pulling images to the local harbor instance.

This repo consists of the 2 shell scripts

- airgap_deploy.sh - Shell script to deploy a SLES pod in the K3s cluster (CP node) to which Airgap-Utility will be installed.
- airgap_image.sh  - Shell script which copies images from the market place to the local harbor


**Notes:** 
- Make sure Harbor SVC External IP is added to your Jumpstation hostfile
```bash
C:\Windows\System32\drivers\etc\hosts
```
- Create new project in Harbor named 'airgap' with unlimited resources

### Steps to install Airgap-Utility

1.	Download the ansible repo using the following command on any of the K3s master node. 
```bash
git clone https://github.com/davis-jacob/lh-caas-airgap.git
```
2.	Edit the yaml file and update proxy details for the Airgap-Utility SLES pod deployment.
```bash
Update values for https_proxy, http_proxy and no proxy
vi lh-caas-airgap/scripts/airgap_pod.yaml
```
3.	Run the script to deploy Airgap-Utility pod 
```bash
cd lh-caas-airgap/scripts
./airgap_deploy.sh
```
**Notes:** 
- Provide the SUSE registration details when prompted

#### Copy Images to the Harbor 
1.	Exec to the Airgap-Utility  pod to run the rest of the commands
```bash
kubectl get pods -n airgap |grep airgap-utility
airgap-utility-76bfc5867c-b26bb   1/1     Running   0          4m31s

kubectl exec -it airgap-utility-76bfc5867c-b26bb -n airgap – bash
```
2.	Clone the Git repo to the Airgap-Utility pod
```bash
git clone https://github.com/davis-jacob/lh-caas-airgap.git
```
3.	Run the script to pull the images to the local harbor
```bash
cd lh-caas-airgap/scripts
./airgap_image.sh
```
4.	Once completed make sure 339 repositories are added to the Harbor project.
