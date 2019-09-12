FROM centos:7.6.1810 as intermediate

#RUN echo $https_proxy

# Update base image
RUN yum -y update && yum clean all

#RUN yum -y install deltarpm unzip wget
RUN yum makecache fast \
    && yum -y install deltarpm unzip \
    && yum clean all

ARG user=wasadmin

ARG group=wasadmin

RUN groupadd $group \
    && useradd $user -g $group -m\
    && chown -R $user:$group /var /opt /tmp

USER $user

###################### IBM Installation Manager ##########################
#RUN wget -q $URL/agent.installer.lnx.gtk.x86_64_1.8.5.zip -O /tmp/IM.zip
COPY --chown=$user:$group InstalMgr1.6.2_LNX_X86_64_WAS_8.5.5.zip /tmp/IM.zip
RUN  mkdir /tmp/im && unzip -qd /tmp/im /tmp/IM.zip \
    && /tmp/im/installc -acceptLicense -accessRights nonAdmin \
    -installationDirectory "/opt/IBM/InstallationManager"  \
    -dataLocation "/var/ibm/InstallationManager" -showProgress \
    && rm -fr /tmp/IM.zip /tmp/im

###### Install IBM WebSphere Application Server ND v855 ################
##COPY with more than one file, destination must be a directory and end with a /

COPY --chown=$user:$group WAS_ND_V8.5.5_*_OF_3.zip /tmp/
RUN  mkdir /tmp/was \
    && unzip -q /tmp/WAS_ND_V8.5.5_1_OF_3.zip -d /tmp/was \
    && rm -rf /tmp/WAS_ND_V8.5.5_1_OF_3.zip \
    && unzip -q /tmp/WAS_ND_V8.5.5_2_OF_3.zip -d /tmp/was \
    && rm -rf /tmp/WAS_ND_V8.5.5_2_OF_3.zip \
    && unzip -q /tmp/WAS_ND_V8.5.5_3_OF_3.zip -d /tmp/was \
    && rm -rf /tmp/WAS_ND_V8.5.5_3_OF_3.zip \
    && /opt/IBM/InstallationManager/eclipse/tools/imcl -showProgress \
    -acceptLicense  install com.ibm.websphere.ND.v85 \
    -repositories /tmp/was/repository.config  \
    -installationDirectory /opt/IBM/WebSphere/AppServer \
    -preferences com.ibm.cic.common.core.preferences.preserveDownloadedArtifacts=false \
    && rm -rf /tmp/was

###### Install IBM WebSphere Application Server ND Fixpack v85510 ################
COPY --chown=$user:$group 8.5.5-WS-WAS-FP0000010-part1.zip /tmp/wasfp1.zip
COPY --chown=$user:$group 8.5.5-WS-WAS-FP0000010-part2.zip /tmp/wasfp2.zip
RUN  mkdir /tmp/wasfp \
    && unzip -qd /tmp/wasfp /tmp/wasfp1.zip  \
    && rm -rf /tmp/wasfp1.zip \
    && unzip -qd /tmp/wasfp /tmp/wasfp2.zip \
    && rm -rf /tmp/wasfp2.zip \
    && /opt/IBM/InstallationManager/eclipse/tools/imcl -showProgress \
    -acceptLicense install com.ibm.websphere.ND.v85 \
    -repositories /tmp/wasfp/repository.config  \
    -installationDirectory /opt/IBM/WebSphere/AppServer \
    -preferences com.ibm.cic.common.core.preferences.preserveDownloadedArtifacts=false \
    && rm -fr /tmp/wasfp

###### Install IBM Java SDK 7.1 ########################
COPY --chown=$user:$group 7.1.3.60-WS-IBMWASJAVA-part1.zip /tmp/java1.zip
COPY --chown=$user:$group 7.1.3.60-WS-IBMWASJAVA-part2.zip /tmp/java2.zip
RUN  mkdir /tmp/java \
    && unzip -qd /tmp/java /tmp/java1.zip  \
    && rm -rf /tmp/java1.zip \
    && unzip -qd /tmp/java /tmp/java2.zip \
    && rm -rf /tmp/java2.zip \
    && /opt/IBM/InstallationManager/eclipse/tools/imcl -showProgress \
    -acceptLicense install com.ibm.websphere.IBMJAVA.v71 \
    -repositories /tmp/java/repository.config \
    -installationDirectory /opt/IBM/WebSphere/AppServer \
    -preferences com.ibm.cic.common.core.preferences.preserveDownloadedArtifacts=false \
    && rm -fr /tmp/java\
    && /opt/IBM/WebSphere/AppServer/bin/managesdk.sh -setCommandDefault -sdkname 1.7.1_64 \
    && /opt/IBM/WebSphere/AppServer/bin/managesdk.sh -setNewProfileDefault -sdkname 1.7.1_64



# final image
FROM centos:7.6.1810

# Update base image
RUN yum -y update && yum clean all

RUN yum -y install sudo epel-release; yum repolist; yum clean all

RUN yum makecache fast \
    && yum -y install deltarpm openssl unzip tar nc \
    && yum clean packages \
    && yum clean headers \
    && yum clean all \
    && rm -rf /var/cache/yum \
    && rm -rf /var/tmp/yum-*

ARG user=wasadmin
ARG group=wasadmin

COPY --from=intermediate /opt /opt

RUN groupadd $group && useradd $user -g $group -m \
    && chown -R $user:$group /opt

USER $user

###### setting and patch ########################
# patch wsadmin.sh to avoid error when deploying apps
RUN sed -i 's/-Xms256m/-Xms1024m/g' /opt/IBM/WebSphere/AppServer/bin/wsadmin.sh \
    && sed -i 's/-Xmx256m/-Xmx1024m/g' /opt/IBM/WebSphere/AppServer/bin/wsadmin.sh

ENV PATH /opt/IBM/WebSphere/AppServer/bin:$PATH