FROM registry.access.redhat.com/ubi8/ubi-minimal

ARG builddate="unknown"
ARG version="unknown"
ARG vcs="unknown"

ENV TMPDIR /tmp
ENV HOME /home/deployer
ENV RHODS_VERSION ${version}

RUN microdnf update -y && \
    microdnf install -y \
      bash \
      tar \
      gzip \
      openssl \
    && microdnf clean all && \
    rm -rf /var/cache/yum

ADD https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/oc.tar.gz $TMPDIR/
RUN tar -C /usr/local/bin -xvf $TMPDIR/oc.tar.gz && \
    chmod +x /usr/local/bin/oc && \
    rm $TMPDIR/oc.tar.gz &&\
    mkdir -p $HOME

COPY deploy.sh $HOME
COPY buildchain.sh $HOME
COPY opendatahub.yaml $HOME
COPY opendatahub-osd.yaml $HOME
COPY rhods-monitoring.yaml $HOME
COPY rhods-notebooks.yaml $HOME
COPY rhods-osd-configs.yaml $HOME
ADD monitoring $HOME/monitoring
ADD consolelink $HOME/consolelink
ADD groups $HOME/groups
ADD jupyterhub $HOME/jupyterhub
ADD partners $HOME/partners
ADD network $HOME/network
ADD cloud-resource-operator $HOME/cloud-resource-operator

RUN chmod 755 $HOME/deploy.sh && \
    chmod 755 $HOME/buildchain.sh && \
    chmod 644 $HOME/opendatahub.yaml && \
    chmod 644 $HOME/opendatahub-osd.yaml && \
    chmod 644 $HOME/rhods-monitoring.yaml && \
    chmod 644 $HOME/rhods-notebooks.yaml && \
    chmod 644 $HOME/rhods-osd-configs.yaml && \
    chmod 644 -R $HOME/monitoring && \
    chmod 644 -R $HOME/groups && \
    chmod 644 -R $HOME/jupyterhub && \
    chmod 644 -R $HOME/network && \
    chmod 644 -R $HOME/cloud-resource-operator && \
    chown 1001:0 -R $HOME &&\
    chmod ug+rwx -R $HOME

# Generate the checksum before we modify the manifest to be version specific.
# This checksum will be deployed in a configmap in a running deployment and so
# if the content other than the rhods/buildchain label value changes, the
# checksum will match
RUN sha256sum $HOME/jupyterhub/cuda-11.0.3/manifests.yaml > $HOME/manifest-checksum

# Update the labels with the specific version value
RUN sed -i 's,rhods/buildchain:.*,rhods/buildchain: cuda-'"${version}"',g' \
       $HOME/jupyterhub/cuda-11.0.3/manifests.yaml


LABEL org.label-schema.build-date="$builddate" \
      org.label-schema.description="Pod to deploy the CR for Open Data Hub" \
      org.label-schema.license="Apache-2.0" \
      org.label-schema.name="ODH deployer" \
      org.label-schema.vcs-ref="$vcs" \
      org.label-schema.vendor="Red Hat" \
      org.label-schema.version="$version"

WORKDIR $HOME
ENTRYPOINT [ "./deploy.sh" ]

USER 1001
