This is an atrocity, but it shows we can probably build the DTK more or less as-is on-cluster (in an entitled cluster) if we need to, as long as we can extract the needed information from the cluster. 

This won't work on a non-entitled cluster (I don't think a cluster-bot cluster works). 

Don't use this on anything you care about. 

```
# builds the DTK and puts it in an imagestream as dtk:latest
./build_on_cluster_dtk.sh
# grabs dtk:latest, builds with it, deploys it to worker pool 
./deploy_dtk_demo.sh
```

Then you should see the pods from the daemonset running: 
```
[jkyros@jkyros-t590 dtk-science-experiments]$ oc get pods
NAME                                 READY   STATUS      RESTARTS   AGE
entitled-dtk-1-build                 0/1     Completed   0          11m
simple-kmod-driver-build-1-build     0/1     Error       0          2m3s
simple-kmod-driver-build-2-build     0/1     Completed   0          118s
simple-kmod-driver-container-46vb5   1/1     Running     0          33s
simple-kmod-driver-container-gt5nq   1/1     Running     0          33s
simple-kmod-driver-container-zr9nk   1/1     Running     0          33s
```

And when you're done:
```
oc delete project simple-kmod-demo
```

I had to tinker with the Dockerfile a little because of how the entitled builds work. 

At the beginning to get the packages:  
```
FROM registry.ci.openshift.org/ocp/4.13:base
  ARG KERNEL_VERSION=''
  ARG RT_KERNEL_VERSION=''
  ARG RHEL_VERSION=''
  
  #Clean out host rhsm otherwise it will prefer it 
  RUN rm /etc/rhsm-host
  #Clean out the ubi and local/internal repos we start with
  RUN rm /etc/yum.repos.d/* 
  #Wake up rhsm and have it give us some repos
  RUN yum repolist
  #Make sure we're pegged to the right version  
  RUN echo ${RHEL_VERSION} > /etc/yum/vars/releasever && yum config-manager --best --setopt=install_weak_deps=False --save
  #Enable the proper channels for our release
  RUN dnf config-manager --set-enabled rhel-8-for-x86_64-baseos-eus-rpms 
  RUN dnf config-manager --set-enabled rhel-8-for-x86_64-rt-rpms 
  RUN dnf config-manager --set-enabled rhocp-4.12-for-rhel-8-x86_64-rpms 
```
And then I didn't feel like going to the trouble to copy the manifests in, so I just pulled them from the web: 
```
#COPY manifests /manifests
  RUN mkdir /manifests && wget -P /manifests https://raw.githubusercontent.com/openshift/driver-toolkit/master/manifests/01-openshift-imagestream.yaml && wget -P /manifests https://raw.githubusercontent.com/openshift/driver-toolkit/master/manifests/image-references
```
But everything else is the same. 
