# Usage: docker build -t ihsbase .

FROM ihs855:centos7 as builder

RUN echo $PATH

# final image that will copy websphere installation folder from builder
FROM centos:7.6.1810

COPY ihsstart.sh /work/
COPY responsefile.txt /opt/IBM/WebSphere/Toolbox/WCT/

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

# The password for user ihsadmin should match the one in responsefile.txt
RUN ln -s /opt/IBM/HTTPServer/java /opt/IBM/WebSphere/Plugins/java \
    && ln -s /opt/IBM/HTTPServer/java /opt/IBM/WebSphere/Toolbox/java \
    && chmod +x /work/ihsstart.sh \
    && /opt/IBM/WebSphere/Toolbox/WCT/wctcmd.sh -tool pct -defLocPathname /opt/IBM/WebSphere/Plugins -defLocName loc1 -createDefinition -response /opt/IBM/WebSphere/Toolbox/WCT/responsefile.txt \
    && /opt/IBM/HTTPServer/bin/htpasswd -cb /opt/IBM/HTTPServer/conf/admin.passwd ihsadmin ihspasswd

CMD ["/work/ihsstart.sh"]