FROM centos:7.6.1810 as intermediate

#RUN echo $https_proxy

# Update base image
RUN yum -y update && yum clean all

#RUN yum -y install deltarpm unzip wget
RUN yum makecache fast \
  && yum -y install deltarpm unzip \
  && yum clean all

###################### IBM Installation Manager ####################
COPY InstalMgr1.6.2_LNX_X86_64_WAS_8.5.5.zip /tmp/IM.zip
RUN  mkdir /tmp/im && unzip -qd /tmp/im /tmp/IM.zip \
  && /tmp/im/installc -acceptLicense -accessRights nonAdmin \
  -installationDirectory "/opt/IBM/InstallationManager"  \
  -dataLocation "/var/ibm/InstallationManager" -showProgress \
  && rm -fr /tmp/IM.zip /tmp/im

###################### Install IBM HTTP Server ################
COPY WAS_V8.5.5_SUPPL_*_OF_3.zip /tmp/
RUN  mkdir /tmp/supp \
  && unzip -q /tmp/WAS_V8.5.5_SUPPL_1_OF_3.zip -d /tmp/supp \
  && rm -rf /tmp/WAS_V8.5.5_SUPPL_1_OF_3.zip \
  && unzip -q /tmp/WAS_V8.5.5_SUPPL_2_OF_3.zip -d /tmp/supp \
  && rm -rf /tmp/WAS_V8.5.5_SUPPL_2_OF_3.zip \
  && unzip -q /tmp/WAS_V8.5.5_SUPPL_3_OF_3.zip -d /tmp/supp \
  && rm -rf /tmp/WAS_V8.5.5_SUPPL_3_OF_3.zip \
  && /opt/IBM/InstallationManager/eclipse/tools/imcl -showProgress \
  -acceptLicense  install com.ibm.websphere.IHS.v85 \
  -repositories /tmp/supp/repository.config  \
  -installationDirectory /opt/IBM/HTTPServer \
  -properties "user.ihs.httpPort=80,user.ihs.allowNonRootSilentInstall=true"

###################### Install WebServer Plugins ########################
RUN /opt/IBM/InstallationManager/eclipse/tools/imcl -showProgress \
  -acceptLicense  install com.ibm.websphere.PLG.v85 \
  -repositories /tmp/supp/repository.config  \
  -installationDirectory /opt/IBM/WebSphere/Plugins 

############ Install WebSphere Customization Tools ###################
RUN /opt/IBM/InstallationManager/eclipse/tools/imcl -showProgress \
  -acceptLicense  install com.ibm.websphere.WCT.v85 \
  -repositories /tmp/supp/repository.config  \
  -installationDirectory /opt/IBM/WebSphere/Toolbox \
  && rm -fr /tmp/supp 

###################### Install IBM HTTPServer Fixpack v85510 ################
COPY 8.5.5-WS-WASSupplements-FP0000010-part1.zip /tmp/spart1.zip
COPY 8.5.5-WS-WASSupplements-FP0000010-part2.zip /tmp/spart2.zip
RUN  mkdir /tmp/suppfp \
  && unzip -qd /tmp/suppfp /tmp/spart1.zip  \
  && rm -rf /tmp/spart1.zip \
  && unzip -qd /tmp/suppfp /tmp/spart2.zip \
  && rm -rf /tmp/spart2.zip \
  && /opt/IBM/InstallationManager/eclipse/tools/imcl -showProgress \
  -acceptLicense  install com.ibm.websphere.IHS.v85 \
  -repositories /tmp/suppfp/repository.config  \
  -installationDirectory /opt/IBM/HTTPServer \
  -properties "user.ihs.httpPort=80,user.ihs.allowNonRootSilentInstall=true"

#Install WebServer Plugins Fixpack
RUN /opt/IBM/InstallationManager/eclipse/tools/imcl -showProgress \
  -acceptLicense  install com.ibm.websphere.PLG.v85 \
  -repositories /tmp/suppfp/repository.config  \
  -installationDirectory /opt/IBM/WebSphere/Plugins \
  && rm -fr /opt/IBM/WebSphere/Plugins/java /tmp/suppfp

############ Install WebSphere Customization Tools Fixpack ################ 
COPY 8.5.5-WS-WCT-FP0000010-part1.zip /tmp/wct1.zip
COPY 8.5.5-WS-WCT-FP0000010-part2.zip /tmp/wct2.zip
RUN mkdir /tmp/wct \
  && unzip  -qd /tmp/wct /tmp/wct1.zip \
  && rm /tmp/wct1.zip \
  && unzip  -qd /tmp/wct /tmp/wct2.zip \
  && rm /tmp/wct2.zip \
  && /opt/IBM/InstallationManager/eclipse/tools/imcl -showProgress \
  -acceptLicense  install com.ibm.websphere.WCT.v85 \
  -repositories /tmp/wct/repository.config  \
  -installationDirectory /opt/IBM/WebSphere/Toolbox \
  && rm -fr /opt/IBM/WebSphere/Toolbox/java /tmp/wct


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

COPY --from=intermediate /opt /opt

ENV PATH /opt/IBM/HTTPServer/bin:$PATH