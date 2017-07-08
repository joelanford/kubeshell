#!/bin/bash

set -e

#
# Set defaults
#
: ${KS_USER:="guest"}
: ${KS_UID:="1000"}

: ${KS_GROUP:="${KS_USER}"}
: ${KS_GID:="${KS_UID}"}

: ${KS_IN_CLUSTER:="false"}
: ${KS_CLUSTER_NAME:="k8s"}
: ${KS_NAMESPACE:=`cat /run/secrets/kubernetes.io/serviceaccount/namespace`}

: ${KS_ENABLE_SUDO:="false"}

#
# Create the group
#
if getent group ${KS_GROUP} > /dev/null 2>&1; then
    echo "group ${KS_GROUP} already exists"
    exit 1
else
    groupadd -g ${KS_GID} ${KS_GROUP}
fi

#
# Create the user
#
if getent passwd ${KS_USER} > /dev/null 2>&1; then
    echo "user ${KS_USER} already exists"
    exit 1
else
    useradd -m -u ${KS_UID} -g ${KS_GID} -G users -s /bin/bash ${KS_USER}
fi

#
# If sudo is enabled, add user to wheel group
#
if [ "${KS_ENABLE_SUDO}" = "true" ]; then
    usermod -aG wheel ${KS_USER}
fi


if [ "${KS_IN_CLUSTER}" = "true" ]; then
    TOKEN=``
    runuser -l ${KS_USER} -c "kubectl config set-cluster ${KS_CLUSTER_NAME} --server=https://kubernetes.default --certificate-authority=/run/secrets/kubernetes.io/serviceaccount/ca.crt 2>&1 > /dev/null"
    runuser -l ${KS_USER} -c "kubectl config set-credentials ${KS_USER} --token=\"`cat /run/secrets/kubernetes.io/serviceaccount/token`\" 2>&1 > /dev/null"
    runuser -l ${KS_USER} -c "kubectl config set-context ${KS_CLUSTER_NAME} --cluster=${KS_CLUSTER_NAME} --user=${KS_USER} --namespace=${KS_NAMESPACE} 2>&1 > /dev/null"
    runuser -l ${KS_USER} -c "kubectl config use-context ${KS_CLUSTER_NAME} 2>&1 > /dev/null"
fi

exec /usr/sbin/shellinaboxd --disable-ssl                                        \
                            --user ${KS_USER}                                    \
                            --group ${KS_GROUP}                                  \
                            --css=/usr/share/shellinabox/white-on-black.css      \
                            --service="/":"${KS_USER}":"${KS_GROUP}":HOME:SHELL