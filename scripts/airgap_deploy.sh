#!/bin/bash

##Create a NS airgap
if [ "$(kubectl get ns airgap |awk ' NR==2 {print $1}')" == "airgap" ]; then
   printf "\nAirgap namespace already exist"
else
   kubectl create ns airgap
fi

###Pull the SLES image
if [[ "$(crictl images -q registry.suse.com/bci/bci-base:latest 2> /dev/null)" == "" ]]; then
   printf "\n\nPulling image from SUSE"
   crictl pull registry.suse.com/bci/bci-base:latest
else
   printf "\n\nImage already available locally"
fi

####Run SLES pod 

if [ "$(kubectl get pods -n airgap| grep -i airgap-utility | awk '{print $3}')" != "Running" ]; then
   printf "\n\nCreating new Airgap Utility pod"
   kubectl create -f airgap_pod.yaml -n airgap
else
   printf "\n\nAirgap Utility Pod already running in the NameSpace airgap\n"
   exit 0
fi

###Get the pod name
sleep 30
pod_name=$(kubectl get pods -n airgap |grep airgap-utility | awk '{print $1}')

### install Ansible and inside the pod

echo "\n\nEnter the email ID for SUSEConnect Subscription:"
read -p "Email ID:" suse_email

echo "\n\nEnter the registration code for SUSEConnect Subscription:"
read -s -p "Registration Code:" suse_pass

##Install packages
kubectl exec -it pod/$pod_name -n airgap -- zypper install -y SUSEConnect
kubectl exec -it pod/$pod_name -n airgap -- SUSEConnect -r $suse_pass -e $suse_email
kubectl exec -it pod/$pod_name -n airgap -- zypper install -y git wget vim awk skopeo
kubectl exec -it pod/$pod_name -n airgap -- zypper addrepo -a 'http://download.opensuse.org/repositories/devel:/tools:/scm/15.3/devel:tools:scm.repo'
kubectl exec -it pod/$pod_name -n airgap -- zypper install -y python3 python3-pip
unset suse_pass suse_email  

##Install the latest version of the Airgap-Utility
kubectl exec -it pod/$pod_name -n airgap -- wget 'https://ezmeral-platform-releases.s3.amazonaws.com/5.4.3/hpeairgaputil-1.3-py2.py3-none-any.whl'
kubectl exec -it pod/$pod_name -n airgap -- pip3 install hpeairgaputil-1.3-py2.py3-none-any.whl
