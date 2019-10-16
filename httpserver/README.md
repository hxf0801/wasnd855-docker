# Building an IBM HTTP Server v8.5.5 image from binaries

## IBM HTTP Server install image

### Overview

An IBM HTTP Server install image can be built by obtaining the following binaries:
* IBM Installation Manager binaries:
  * InstalMgr1.6.2_LNX_X86_64_WAS_8.5.5.zip 

* IBM HTTP Server,IBM WebServer Plugins and IBM WebSphere Customization Tools binaries:
  * WAS_V8.5.5_SUPPL_1_OF_3.zip(CIK1VML)
  * WAS_V8.5.5_SUPPL_1_OF_3.zip(CIK1WML)
  * WAS_V8.5.5_SUPPL_1_OF_3.zip(CIK1XML)

  Fixpack 8.5.5.10 binaries:
  * 8.5.5-WS-WASSupplements-FP0000010-part1.zip
  * 8.5.5-WS-WASSupplements-FP0000010-part2.zip
  * 8.5.5-WS-WCT-FP0000010-part1.zip
  * 8.5.5-WS-WCT-FP0000010-part2.zip

### Dockerfile

IBM HTTP Server install image is created using a multi-stage Dockerfile to reduce the final image size:

* [centos7.ihs.Dockerfile](./install/centos7.ihs.Dockerfile)

This Dockerfile perform the following actions:
 
1. Installs IBM Installation Manager
2. Installs IBM HTTP Server 
3. Installs WebServer Plugins
4. Installs WebSphere Customization Tools
5. Updates IBM HTTP Server with the Fixpack
6. Updates WebServer Plugins with the Fixpack
7. Updates WebSphere Customization Tools with the Fixpack

8. Copies the startup script to the image
9. When the container is started the IHS server is started

### Building the IBM HTTP Server install image

> Build the image using:

```bash
docker build -t ihs855:centos7 -f centos7.ihs.Dockerfile .
```

> Running the IBM HTTP Server install image                                                               
```bash
docker run --name ihs -h ihs -p 80:80 ihs855:centos7          
```

## IBM HTTP Server image with webserver definition

### Dockerfile

Create a IBM HTTP Server image with webserver definition by the following Dockerfile:

* [Dockerfile](Dockerfile)

This Dockerfile perform the following actions:
 
1. Copy IBM HTTP Server installation folder from image `ihs855:centos7` to the image
2. Copies the startup script to the image
3. Create a webserver definition
    ```bash
    COPY responsefile.txt /opt/IBM/WebSphere/Toolbox/WCT/
    # ...
    RUN /opt/IBM/WebSphere/Toolbox/WCT/wctcmd.sh -tool pct -defLocPathname /opt/IBM/WebSphere/Plugins -defLocName loc1 -createDefinition -response /opt/IBM/WebSphere/Toolbox/WCT/responsefile.txt
    ```

    Refer to [Parameters of the pct tool](https://www.ibm.com/support/knowledgecenter/SSAW57_9.0.5/com.ibm.websphere.nd.multiplatform.doc/ae/tins_pctcl_using.html) for detailed explanation to responsefile.txt.
4. add password for admin user to http administrative server
5. When the container is started the IHS server is started

### Building the image

> Build the image using:

```bash
docker build -t ihsbase .
```

Explore the image in Windows git bash prompt:
```bash
$ winpty docker run --rm -it ihsbase bash -il
```

## Configure the IBM HTTP Server with WAS traditional

Now that we have IBM HTTP Server and IBM WebSphere Application Server traditional images, we will configure IBM HTTP Server to work with WebSphere Application Server running in containers.

* first start ihs server and was server respectively
    ```bash
    $ docker network create net1
    $ docker network ls

    # start ibm http server
    $ docker run --name ihs -h ihs --net=net1 -p 80:80 -d ihsbase
    
    # Starting ihs's administrative server to let was server connect it later
    $ docker exec ihs //opt/IBM/HTTPServer/bin/adminctl start

    # start websphere with defined profile
    $ docker run --name test -h test -e UPDATE_HOSTNAME=true -p 9060:9060 -p 9043:9043 --net=net1 -d wasnd855-s2i-citisit

    # check containers
    $ docker ps -a
    CONTAINER ID        IMAGE                   PORTS                                                   NAMES
    a904a50c3fd8        wasnd855-s2i-citisit    0.0.0.0:9043->9043/tcp, 9080/tcp,                       test
                                                  0.0.0.0:9060->9060/tcp, 9443/tcp      
    b8b3f316dcd2        ihsbase                 0.0.0.0:80->80/tcp                                      ihs
    ```

* second use was server's administration console to create `plugin-cfg.xml` file

    Login websphere ISC to manually create and setup webserver: http://192.168.99.105:9060/ibm/console
    
    Navigate to **Server** | **Server Types** | **Web Servers**, click "**New...**" button to create a new web server, choose the following values to comply with `responsefile.txt`:
    * Web server name=webserver1
    * Type=IBM HTTP Server
    * Host name=ihs
    * Port=80
    * Platform Type=Linux
    * Administration Server Port=8008
    * Username=ihsadmin
    * Password=ihspasswd

    Follow the wizard to finish the creation, and start the newly created Web Server. And then click below buttons in order:
    * **Generate Plug-in** button 
        ```
        Plug-in configuration file = /opt/IBM/WebSphere/AppServer/profiles/AppSrv01/config/cells/DefaultCell01/nodes/ihs-node/servers/webserver1/plugin-cfg.xml
        ```

        This results in a new node `ihs-node` created alongside with old node `DefaultNode01` on Websphere container.

    * **Propagate Plug-in** button
        ```
        PLGC0062I: The plug-in configuration file is propagated from /opt/IBM/WebSphere/AppServer/profiles/AppSrv01/config/cells/DefaultCell01/nodes/ihs-node/servers/webserver1/plugin-cfg.xml to /opt/IBM/WebSphere/Plugins/config/webserver1/plugin-cfg.xml on the Web server computer.
        ```

* finally, save the changes made to containers
    
    Now that we got the `plugin-cfg.xml`, we can extract it from the ihs container, or we can save the snapshot of containers for future reference. Here we demostrate how to save changes made to a container.

    ```bash
    $ docker image ls
    REPOSITORY                TAG                 IMAGE ID            CREATED             SIZE
    ihsbase                   latest              ed27f0e0f8d6        6 minutes ago       994MB
    ihs855                    centos7             1f15aa6ab8e2        16 hours ago        990MB
    wasnd855-s2i-citisit      latest              ca33f1d7b965        17 hours ago        3.47GB
    wasnd855-s2i              latest              e40cc497f12f        17 hours ago        1.94GB
    centos/s2i-core-centos7   latest              6948865d43a4        6 days ago          236MB
    wasbase                   latest              95b9660677ee        13 days ago         2.1GB
    centos                    7.6.1810            f1cb7c7d58b7        7 months ago        202MB
    ```

    Use container id `a904a50c3fd8` for websphere server and `b8b3f316dcd2` for http server:
    ```bash
    # Usage:  docker commit [OPTIONS] CONTAINER [REPOSITORY[:TAG]]
    $ docker commit a904a50c3fd8 wasnd855-s2i-citisit:ihs-was-ok
    sha256:d568705b7f47e28f8ed589373d59cfe532391efe4fe4c7ff47cc62c812bf5c00

    $ docker commit b8b3f316dcd2 ihsbase:ihs-was-ok
    sha256:a77c2764885948ce98bd832697b406db9668335d985cd785f7a6f7ed88edb108
    ```

    ```bash
    $ docker image ls
    REPOSITORY                TAG                 IMAGE ID            CREATED              SIZE
    ihsbase                   ihs-was-ok          a77c27648859        41 seconds ago       995MB
    wasnd855-s2i-citisit      ihs-was-ok          d568705b7f47        About a minute ago   4.21GB
    ihsbase                   latest              ed27f0e0f8d6        About an hour ago    994MB
    ihs855                    centos7             1f15aa6ab8e2        18 hours ago         990MB
    wasnd855-s2i-citisit      latest              ca33f1d7b965        18 hours ago         3.47GB
    wasnd855-s2i              latest              e40cc497f12f        18 hours ago         1.94GB
    centos/s2i-core-centos7   latest              6948865d43a4        6 days ago           236MB
    wasbase                   latest              95b9660677ee        13 days ago          2.1GB
    centos                    7.6.1810            f1cb7c7d58b7        7 months ago         202MB
    ```

**`Noteworthy:`** 
1. The key to connect IHS server to was server is the `/opt/IBM/WebSphere/Plugins/config/webserver1/plugin-cfg.xml` which defines the information on was server. If was server changes, the plugin config file `plugin-cfg.xml` also needs to be updated accordingly.
2. All things we do in this section are to let was server to generate _plugin-cfg.xml_ and propagate it to web server. So we have to 
    * start ihs administrative server on ihs web server which will accept the access requests from was server
    * define a web server definition on web server
    * create a web server on the administrative console on was server
    * use administrative console on was server to connect ihs administrative server on ihs web server to pass through the generated _plugin-cfg.xml_.