#!/bin/bash

# Get the coreos image
COREOS=$(oc adm release info $i --image-for=rhel-coreos-8)
# Get the machine-os-content 
MOC=$(oc adm release info $i --image-for=machine-os-content)
# Get the rt kernel version off machine-os-content
KERNEL_RT=$(skopeo inspect docker://$MOC --no-tags  |jq  -r '.Labels[ "com.coreos.rpm.kernel-rt-core" ]')
# Get the kernel version off rhel-coreos-8
KERNEL=$(skopeo inspect docker://$COREOS --no-tags  |jq  -r '.Labels[ "ostree.linux" ]')

#TODO(jkyros): Get the OCP version + Rhel version 

OCPVERSION=4.13
RHEL_VERSION=8.6
oc apply -f build-kmod.yaml 
oc start-build -n simple-kmod-demo simple-kmod-driver-build --build-arg KMODVER=DEMO --build-arg=DTK=image-registry.openshift-image-registry.svc:5000/simple-kmod-demo/dtk:latest --build-arg KVER=$KERNEL --follow

# let us schedule our module insertion pods in our namespace
oc adm policy add-scc-to-user privileged -z simple-kmod-driver-container -n simple-kmod-demo
oc apply -f apply-kmod.yaml
# yes this should be a manifest I include with apply-kmod
oc adm policy add-scc-to-user privileged -z simple-kmod-driver-container -n simple-kmod-demo


