FROM centos:7

ARG GIT_COMMIT
LABEL maintainer="joe.lanford@gmail.com" gitCommit="${GIT_COMMIT}"

RUN yum install -y sudo epel-release bash-completion && yum install -y shellinabox && \
    yum clean all && \
    rm -rf /var/cache/yum

ARG KUBECTL_VERSION
RUN curl -Ls https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && \
    chmod 755 /usr/local/bin/kubectl && \
    kubectl completion bash > /etc/profile.d/kube_completion.sh && \
    chmod 644 /etc/profile.d/kube_completion.sh

ARG DOCKER_VERSION
RUN curl -Ls https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz | tar -xz -C /tmp && \
    rm -rf /tmp/docker/dockerd && \
    mv /tmp/docker/docker /usr/local/bin/ && \
    rm -rf /tmp/docker

RUN sed -i 's/%wheel	ALL=(ALL)	ALL/%wheel	ALL=(ALL)	NOPASSWD: ALL/g' /etc/sudoers

ADD rootfs/run.sh /run.sh

ENTRYPOINT ["/run.sh"]
EXPOSE 4200
