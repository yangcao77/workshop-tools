FROM registry.access.redhat.com/ubi8-minimal:8.1-407

ENV HOME=/home/developer

RUN mkdir -p /projects ${HOME}

# odo and oc versions have to match the ones defined in https://github.com/redhat-developer/vscode-openshift-tools/blob/master/src/tools.json
ENV GLIBC_VERSION=2.30-r0 \
    ODO_VERSION=v2.2.3 \
    OC_VERSION=4.7 \
    KUBECTL_VERSION=v1.20.6 \
    MAVEN_VERSION=3.6.3 \
    JDK_VERSION=11 \
    JAVA_TOOL_OPTIONS="-Djava.net.preferIPv4Stack=true"

# # install oc
# RUN curl -o- -L https://mirror.openshift.com/pub/openshift-v4/clients//ocp/stable-${OC_VERSION}/openshift-client-linux.tar.gz | tar xvz -C /usr/local/bin && \
#     chmod +x /usr/local/bin/oc && \
#     oc version --client

# # install odo
# RUN curl -o /usr/local/bin/odo https://mirror.openshift.com/pub/openshift-v4/clients/odo/${ODO_VERSION}/odo-linux-amd64 && \
#     chmod +x /usr/local/bin/odo && \
#     odo version --client

RUN microdnf install -y \
        bash curl wget tar gzip java-${JDK_VERSION}-openjdk-devel git openssh which httpd python36 procps && \
    microdnf -y clean all && rm -rf /var/cache/yum && \
    echo "Installed Packages" && rpm -qa | sort -V && echo "End Of Installed Packages"

# install oc
RUN wget -qO- https://mirror.openshift.com/pub/openshift-v4/clients//ocp/stable-${OC_VERSION}/openshift-client-linux.tar.gz | tar xvz -C /usr/local/bin && \
    oc version --client

# install odo
RUN wget -O /usr/local/bin/odo https://mirror.openshift.com/pub/openshift-v4/clients/odo/${ODO_VERSION}/odo-linux-amd64 && \
    chmod +x /usr/local/bin/odo && \
    odo preference set ConsentTelemetry false && \
    odo version --client


# install kubectl
ADD https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl /usr/local/bin/kubectl
RUN chmod +x /usr/local/bin/kubectl && \
    kubectl version --client

# install maven
ENV MAVEN_HOME /usr/lib/mvn
ENV PATH ${MAVEN_HOME}/bin:$PATH

RUN wget http://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz && \
  tar -zxvf apache-maven-$MAVEN_VERSION-bin.tar.gz && \
  rm apache-maven-$MAVEN_VERSION-bin.tar.gz && \
  mv apache-maven-$MAVEN_VERSION /usr/lib/mvn

# Configure Java
ENV JAVA_HOME ${GRAALVM_HOME}

# Entrypoints
ADD etc/entrypoint.sh ${HOME}/entrypoint.sh

# Change permissions to let any arbitrary user
RUN for f in "${HOME}" "/etc/passwd" "/projects"; do \
      echo "Changing permissions on ${f}" && chgrp -R 0 ${f} && \
      chmod -R g+rwX ${f}; \
    done

ENTRYPOINT [ "/home/developer/entrypoint.sh" ]
WORKDIR /projects
CMD tail -f /dev/null