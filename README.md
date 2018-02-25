# What is kubeshell

kubeshell is an HTML5-based CentOS 7-based shell installed with kubectl and bash completion

# Usage

```
docker run -e KS_USER=guest        \
           -e KS_UID=1000          \
           -e KS_GROUP=guest       \
           -e KS_GID=1000          \
           -e KS_ENABLE_SUDO=false \
           -e KS_IN_CLUSTER=false  \
           -e KS_CLUSTER_NAME=k8s  \
           -e KS_NAMESPACE=default \
    -p 4200:4200 joelanford/kubeshell
```

* **KS_USER** - the username of the login user (default "guest")
* **KS_UID**  - the uid of the login user (default "1000")
* **KS_GROUP** - the primary group of the login user (default "$KS_USER")
* **KS_GID** - the gid of the primary group of the login user (default "$KS_UID")
* **KS_ENABLE_SUDO** - whether the login user has full sudo access (default "false")
* **KS_IN_CLUSTER** - whether kubeshell is running as a pod in a k8s cluster (default "false")
  * if KS_IN_CLUSTER=true, a default context is created using the pod's service account credentials
  * if KS_IN_CLUSTER=false, no default context is created
* **KS_CLUSTER_NAME** - if KS_IN_CLUSTER=true, the name of the cluster used to generate the default kubectl configuration context (default "k8s")
* **KS_NAMESPACE** - if KS_IN_CLUSTER=true, the namespace used to generate the default kubectl configuration context (default is the service account namespace)

# Authentication

**IMPORTANT**: Access to the kubeshell port should be protected by a reverse proxy, such as a sidecar nginx container or a Kubernetes ingress controller. There is no authenication built into the kubeshell image directly.
