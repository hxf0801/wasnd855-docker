# Usage: docker build -t ihsbase-openshift .

FROM ihsbase

#Users: default(uid=1001), root(uid=0). Both are in root group(gid=0)
##openshift container runs image using Arbitrary User ID (1001) which is a member of root group
COPY plugin-cfg.template /opt/IBM/WebSphere/Plugins/config/webserver1/
COPY ihsstart_openshift.sh /work/

RUN truncate -s 0 /opt/IBM/WebSphere/Plugins/logs/webserver1/http_plugin.log \
    && mv /opt/IBM/WebSphere/Plugins/config/webserver1/plugin-cfg.xml /opt/IBM/WebSphere/Plugins/config/webserver1/plugin-cfg.xml.bak \
    && cp -v /opt/IBM/WebSphere/Plugins/config/webserver1/plugin-cfg.template /opt/IBM/WebSphere/Plugins/config/webserver1/plugin-cfg.xml

#ports the container listens. 
##EXPOSE just opens port on containter to communicate inter-container, and does NOT let them accessible to host
##Must use 'docker run -p hostPort:containerPort imageName' to expose port to host
EXPOSE 80

# TODO: Set the default CMD for the image
CMD ["/work/ihsstart_openshift.sh"]