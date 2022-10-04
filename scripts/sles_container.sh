#!/bin/bash

##Create a NS airgap
if [ "$(kubectl get ns airgap |awk ' NR==2 {print $1}')" == "airgap" ]; then
   echo "airgap namespace already exist"
else
   kubectl create ns airgap
fi

###Pull the SLES image
###crictl pull registry.suse.com/bci/bci-base:latest

if [[ "$(crictl images -q registry.suse.com/bci/bci-base:latest 2> /dev/null)" == "" ]]; then
   echo "Pulling image from SUSE"
   crictl pull registry.suse.com/bci/bci-base:latest
else
   echo "Image already available locally"
fi

#### run SLES pod 

if [ "$(kubectl get pods -n airgap| grep -i ansible-seed | awk '{print $3}')" != "Running" ]; then
   echo "Creating new ansible seed server"
   kubectl create -f sles_pod.yaml -n airgap
else
   echo "Ansible seed Pod already running in NS airgap"
   exit 0
fi

###Get the pod name
sleep 30
pod_name=$(kubectl get pods -n airgap |grep ansible-seed | awk '{print $1}')

###### install Ansible and inside the pod
#kubectl exec -it pod/airgap-utility1-dff8c459f-7pmj7 -n airgap -- zypper install ansible

echo "Enter the email ID for SUSEConnect Subscription:"
read -p "Email ID:" suse_email

echo "Enter the registration code for SUSEConnect Subscription:"
read -s -p "Registration Code:" suse_pass


kubectl exec -it pod/$pod_name -n airgap -- zypper install -y SUSEConnect
kubectl exec -it pod/$pod_name -n airgap -- SUSEConnect -r $suse_pass -e $suse_email
kubectl exec -it pod/$pod_name -n airgap -- SUSEConnect -p PackageHub/15.4/x86_64
kubectl exec -it pod/$pod_name -n airgap -- zypper install -y ansible git sshpass wget vim

unset suse_pass suse_email  
