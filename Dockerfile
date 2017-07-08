FROM centos:7
LABEL maintainer="joe.lanford@gmail.com"

RUN yum install -y sudo epel-release bash-completion && yum install -y shellinabox && yum clean all

ARG KUBECTL_VERSION

RUN curl -Ls https://storage.googleapis.com/kubernetes-release/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && \
    chmod 755 /usr/local/bin/kubectl && \
    kubectl completion bash > /etc/profile.d/kube_completion.sh && \
    chmod 644 /etc/profile.d/kube_completion.sh

RUN sed -i 's/%wheel	ALL=(ALL)	ALL/%wheel	ALL=(ALL)	NOPASSWD: ALL/g' /etc/sudoers

ADD rootfs/run.sh /run.sh

ENTRYPOINT ["/run.sh"]
EXPOSE 4200
