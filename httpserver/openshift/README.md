# IBM HTTP Server image for OpenShift

Before this task, we should have one workable `plugin-cfg.xml`. But in OpenShift, the was server host name is dynamic, by default it is the container name (AKA pod name). So the was host should be parameterized, and provided via environment variable `WAS_HOST_NAME` in DeploymentConfig.

## Dockerfile

Use new start server script [`ihsstart_openshift.sh`](ihsstart_openshift.sh) for the IBM HTTP Server image by the following Dockerfile:

* [Dockerfile](Dockerfile)

This Dockerfile extends IBM HTTP Server image `ihsbase:latest` to add a new function that will replace was host name in `plugin-cfg.xml` with inputed environment variable exactly before starting ihs server.

## Building

> Build the image using:

```bash
docker build -t ihsbase-openshift .
```

## Testing

```bash
$ docker image ls
REPOSITORY                TAG                 IMAGE ID            CREATED             SIZE
ihsbase-openshift         latest              24ced57e67cc        4 minutes ago       994MB
ihsbase                   latest              ed27f0e0f8d6        3 hours ago         994MB
ihs855                    centos7             1f15aa6ab8e2        22 hours ago        990MB
wasnd855-s2i-citisit      latest              ca33f1d7b965        23 hours ago        3.47GB
wasnd855-s2i              latest              e40cc497f12f        23 hours ago        1.94GB
centos/s2i-core-centos7   latest              6948865d43a4        6 days ago          236MB
wasbase                   latest              95b9660677ee        2 weeks ago         2.1GB
centos                    7.6.1810            f1cb7c7d58b7        7 months ago        202MB

$ docker network create net1

$ docker run --name citisit -h citisit -e UPDATE_HOSTNAME=true -p 9080:9080 -p 9443:9443 -p 9060:9060 -p 9043:9043 --net=net1 -d wasnd855-s2i-citisit
$ docker run --name ihs -h ihs -e WAS_HOST_NAME=citisit -p 80:80 --net=net1 -d ihsbase-openshift

$ docker cp ihs:/opt/IBM/WebSphere/Plugins/logs /d/tmp/x/openshift/ihs/
$ docker cp ihs:/opt/IBM/WebSphere/Plugins/config /d/tmp/x/openshift/ihs/
```

Enter in browser: http://192.168.99.105/cda


## ?? Summary This technical document provides details on how to setup IBM HTTP Server (IHS) to run as non-root user.
Create a new user called ihsadmin1 and configure IHS to run as a user ihsadmin1 using setcap:

1. As root, stop IHS:
    /opt/IBM/HTTPServer/bin/apachectl stop
2. Run setcap against the httpd process:
    $ setcap CAP_NET_BIND_SERVICE+ep /opt/IBM/HTTPServer/bin/httpd
3. Change ownership on various files:
    chown ihsadmin1 /opt/IBM/HTTPServer/logs
    chown ihsadmin1 /opt/IBM/HTTPServer/logs/*
    chown ihsadmin1 /opt/IBM/WebSphere/Plugins/config/webserver1/plugin-key.*
    chown ihsadmin1 /opt/IBM/WebSphere/Plugins/logs/webserver1
    chown ihsadmin1 /opt/IBM/WebSphere/Plugins/logs/webserver1/*
4. Update load library configuration:
    cd /etc/ld.so.conf.d/
    echo /opt/IBM/HTTPServer/lib > httpd-lib.conf
    echo /opt/IBM/HTTPServer/gsk8/lib64 >> httpd-lib.conf
    mv /etc/ld.so.cache /etc/ld.so.cache.old
    /sbin/ldconfig
5. Start IHS as ihsadmin1
    sudo -u ihsadmin1 /opt/IBM/HTTPServer/bin/apachectl start