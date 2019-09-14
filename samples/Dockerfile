FROM wasnd855:centos7 as builder

RUN echo $PATH

# final image that will copy websphere installation folder from builder
FROM centos:7.6.1810

ARG USER=was
ARG GROUP=was

ARG PROFILE_NAME=AppSrv01
ARG CELL_NAME=DefaultCell01
ARG NODE_NAME=DefaultNode01
ARG HOST_NAME=localhost
ARG SERVER_NAME=server1
ARG ADMIN_USER_NAME=wsadmin
ARG ADMIN_USER_PWD=changeme

COPY scripts/ /work/

RUN yum -y update && yum clean all
RUN yum -y install sudo epel-release; yum repolist; yum clean all

RUN yum makecache fast \
    && yum -y install deltarpm openssl unzip tar nc ksh which\
    && yum clean packages \
    && yum clean headers \
    && yum clean all \
    && rm -rf /var/cache/yum \
    && rm -rf /var/tmp/yum-*

RUN groupadd $GROUP -o --gid 0 \
    && useradd $USER -g $GROUP -m --uid 1001 \
    && mkdir /opt/IBM \
    && chmod -R +x /work/* \
    && mkdir /etc/websphere \
    && mkdir /work/config \
    && chown -R $USER:$GROUP /work /opt/IBM /etc/websphere

COPY --chown=1001:0 --from=builder /opt/IBM /opt/IBM

USER $USER

ENV PATH=/opt/IBM/WebSphere/AppServer/bin:$PATH \
    PROFILE_NAME=$PROFILE_NAME \
    SERVER_NAME=$SERVER_NAME \
    CELL_NAME=$CELL_NAME \
    NODE_NAME=$NODE_NAME \
    ADMIN_USER_NAME=$ADMIN_USER_NAME \
    EXTRACT_PORT_FROM_HOST_HEADER=true

RUN /work/set_password.sh $ADMIN_USER_PWD; /work/create_profile.sh

USER root
RUN ln -s /opt/IBM/WebSphere/AppServer/profiles/${PROFILE_NAME}/logs /logs && chown $USER:$GROUP /logs
USER $USER

CMD ["/work/start_server.sh"]