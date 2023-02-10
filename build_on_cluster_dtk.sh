#!/bin/bash
oc create namespace simple-kmod-demo
oc project simple-kmod-demo
# Copy the entitlement secret into our namespace 
oc delete secret etc-pki-entielement
oc get secret etc-pki-entitlement --namespace=openshift-config-managed -o yaml | sed 's/namespace: .*/namespace: simple-kmod-demo/' | oc create -f -
oc delete buildconfig entitled-dtk
oc delete imagestreamtag dtk:latest
oc create -f entitled-dtk.yaml 

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
oc start-build entitled-dtk --build-arg KERNEL_VERSION=$KERNEL --build-arg KERNEL_RT_VERSION=$KERNEL_RT --build-arg RHEL_VERSION=$RHEL_VERSION --follow
