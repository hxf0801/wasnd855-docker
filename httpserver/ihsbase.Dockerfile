FROM ihs855:centos7 as builder

RUN echo $PATH

# final image that will copy websphere installation folder from builder
FROM centos:7.6.1810

COPY ihsstart.sh /work/

RUN yum -y update && yum clean all
RUN yum -y install sudo epel-release; yum repolist; yum clean all

RUN yum makecache fast \
    && yum -y install deltarpm openssl unzip tar nc ksh which\
    && yum clean packages \
    && yum clean headers \
    && yum clean all \
    && rm -rf /var/cache/yum \
    && rm -rf /var/tmp/yum-*

COPY --from=builder /opt /opt

ENV PATH=/opt/IBM/HTTPServer/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN ln -s /opt/IBM/HTTPServer/java /opt/IBM/WebSphere/Plugins/java \
    && ln -s /opt/IBM/HTTPServer/java /opt/IBM/WebSphere/Toolbox/java \
    && chmod +x /work/ihsstart.sh

CMD ["/work/ihsstart.sh"]