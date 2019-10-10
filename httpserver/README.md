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

## IBM HTTP Server production image

### Dockerfile

IBM HTTP Server production image is created by the following Dockerfile:

* [ihsbase.Dockerfile](ihsbase.Dockerfile)

This Dockerfile perform the following actions:
 
1. Copy IBM HTTP Server installation folder from image `ihs855:centos7` to the image
2. Copies the startup script to the image
3. When the container is started the IHS server is started

### Building the IBM HTTP Server production image

> Build the image using:

```bash
docker build -t ihsbase -f ihsbase.Dockerfile .
```

> Running the IBM HTTP Server production image                                                               
```bash
docker run --name ihs -h ihs -p 80:80 ihsbase          
```

## configure the IBM HTTP Server with WAS traditional

Now that we have IBM HTTP Server and IBM WebSphere Application Server traditional images, we will configure IBM HTTP Server to work with WebSphere Application Server running in containers.

* first create a working image with webserver definition from 
`ihsbase` image
    * Dockerfile
    ```bash
    FROM ihsbase
    COPY responsefile.txt /opt/IBM/WebSphere/Toolbox/WCT/
    RUN /opt/IBM/WebSphere/Toolbox/WCT/wctcmd.sh -tool pct -defLocPathname /opt/IBM/WebSphere/Plugins -defLocName loc1 -createDefinition -response /opt/IBM/WebSphere/Toolbox/WCT/responsefile.txt
    ```

    * run Dockerfile
    ```bash
    docker build -t ihsimage .
    ```

* and then start ihs container from the new image `ihsimage`
    ```bash
    $ docker network create net1
    $ docker network ls

    # start ibm http server
    $ docker run --name ihs -h ihs --net=net1 -p 80:80 -d ihsimage
    # add password for user ihsadmin
    $ docker exec ihs /opt/IBM/HTTPServer/bin/htpasswd -cb /opt/IBM/HTTPServer/conf/admin.passwd ihsadmin ihspasswd
    $ docker exec ihs /opt/IBM/HTTPServer/bin/adminctl start

    # start websphere with defined profile
    $ docker run --name test -h test -e UPDATE_HOSTNAME=true -p 9060:9060 -p 9043:9043 --net=net1 -d wasbase

    # check containers
    $ docker ps -a
    CONTAINER ID        IMAGE               PORTS                                            NAMES
    fe494ac03c4c        wasbase             0.0.0.0:9043->9043/tcp, 0.0.0.0:9060->9060/tcp   test
    25f65fbee825        ihsimage            0.0.0.0:80->80/tcp                               ihs
    ```
    
    Login websphere ISC to manually create and setup webserver: http://192.168.99.107:9060/ibm/console
    
    Navigate to Server | Server Types | Web Servers, click "New..." button to create a new web server, choose the following values to comply with `responsefile.txt`:
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
    
        Plug-in configuration file = /opt/IBM/WebSphere/AppServer/profiles/AppSrv01/config/cells/DefaultCell01/nodes/ihs-node/servers/webserver1/plugin-cfg.xml

    * **Propagate Plug-in** button
    
        PLGC0062I: The plug-in configuration file is propagated from /opt/IBM/WebSphere/AppServer/profiles/AppSrv01/config/cells/DefaultCell01/nodes/ihs-node/servers/webserver1/plugin-cfg.xml to /opt/IBM/WebSphere/Plugins/config/webserver1/plugin-cfg.xml on the Web server computer.
    
    This results in a new node `ihs-node` created alongside with old node `DefaultNode01` on Websphere container. At the same time, a new folder `/opt/IBM/WebSphere/Plugins/config/webserver1` created on the Web server container.

* finally, save the changes
    ```bash
    $ docker image ls
    REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
    ihsimage            latest              1e014ac93c30        About an hour ago   994MB
    ihsbase             latest              8ca5915d0208        About an hour ago   993MB
    ihs855              centos7             5f63b77ee240        2 hours ago         990MB
    wasbase             latest              95b9660677ee        8 days ago          2.1GB
    centos              7.6.1810            f1cb7c7d58b7        6 months ago        202MB
    ```

    Use container id `fe494ac03c4c` for websphere and `25f65fbee825` for http server:
    ```bash
    # Usage:  docker commit [OPTIONS] CONTAINER [REPOSITORY[:TAG]]
    $ docker commit fe494ac03c4c wasbase_ihs
    sha256:ea705d2736446e0393595e558e707be52b543c3408a47525dd61505a26587290

    $ docker commit 25f65fbee825 ihs
    sha256:283179a58c5016eacfd3d28bc9e775ab21306a79a9c312221e1201e7160af508
    ```

    ```bash
    $ docker image ls
    REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
    ihs                 latest              283179a58c50        18 minutes ago      994MB
    wasbase_ihs         latest              ea705d273644        21 minutes ago      2.18GB
    ihsimage            latest              1e014ac93c30        2 hours ago         994MB
    ihsbase             latest              8ca5915d0208        2 hours ago         993MB
    ihs855              centos7             5f63b77ee240        2 hours ago         990MB
    wasbase             latest              95b9660677ee        8 days ago          2.1GB
    centos              7.6.1810            f1cb7c7d58b7        6 months ago        202MB
    ```