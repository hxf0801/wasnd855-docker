# How to build WebSphere traditional image with application installed

According to Docker's best practices you should create a new image (`"From baseimage"`) which adds a single application and the corresponding configuration. You should avoid configuring the image manually (after it started) via Admin Console or wsadmin (unless it is for debugging purposes) because such changes won't be present if you spawn a new container from the image. 

## Building base image including only WebSphere profile
So first, create a base image which extends the result from `Dockerfile` under folder *install*. It finishes the following tasks:
1. Create a standalone **WAS profile and server** with specified name;
2. automatically start the server once running the image to create a new container.

> To build with specified values:
```bash
docker build -t wasbase . \
--build-arg PROFILE_NAME=AppSrv01 \
--build-arg SERVER_NAME=server1 \
--build-arg CELL_NAME=DefaultCell01 \
--build-arg NODE_NAME=DefaultNode01 \
--build-arg ADMIN_USER_NAME=wasadmin \
--build-arg ADMIN_USER_PWD=Broadway32
```
Note to remember the admin user **`wasadmin`** and its password **`Broadway32`** which is required to log in the administrative console.

> To build with default values. Default user and password is **`wsadmin`** and **`changeme`**, you can change it with build argument `--build-arg ADMIN_USER_NAME=wasadmin --build-arg ADMIN_USER_PWD=Broadway32`:
```bash
docker build -t wasbase . 
```

> To run the base image
```bash
docker run --name test -h test -e UPDATE_HOSTNAME=true \
  -e PROFILE_NAME=AppSrv01 -e CELL_NAME=DefaultCell01 \
  -e NODE_NAME=DefaultNode01 -e SERVER_NAME=server1 \
  -e ADMIN_USER_NAME=wasadmin \
  -p 9043:9043 -p 9443:9443 -p 9060:9060 -p 9080:9080 -d wasbase 
``` 

## Building an application image 
The key point to take-away from the sections below is that your application Dockerfile should always follow a pattern similar to:

```
FROM wasbase
# copy property files and jython scripts, using the flag `--chown=was:root` to set the appropriate permission
RUN /work/configure.sh
```

This will result in a Docker image that has your application and configuration pre-loaded.

### Deploy WebSphere shipped application and ISC console

Navigate to directory `isclite-app` to know how to install the administrative console application in a WebSphere container.

### Adding properties during build phase

For example, if you had the following `/work/config/001-was-config.props`:

```
ResourceType=JavaVirtualMachine
ImplementingResourceType=Server
ResourceId=Cell=!{cellName}:Node=!{nodeName}:Server=!{serverName}:JavaProcessDef=:JavaVirtualMachine=
AttributeInfo=jvmEntries
#
#
#Properties
#
initialHeapSize=2048 #integer,default(0)
```

You can then create a new image which has this configuration by simply building the following Dockerfile:

```
FROM ibmcom/websphere-traditional:latest
COPY --chown=was:root was-config.props /work/config
RUN /work/configure.sh
```

You may use numeric prefix on your prop files names, so props the have dependencies can be applied in an adequate order.

### Adding an application and advanced configuration during build phase 

Similar to the example above, you can also deploy an application and advanced configuration by placing their Jython (`.py`) scripts under
the folder `/work/config`.  

Putting it all together, you would have a Dockerfile such as:

```
FROM ibmcom/websphere-traditional:latest
COPY --chown=was:root was-config.props /work/config
COPY --chown=was:root myApp.war /work/app
COPY --chown=was:root myAppDeploy.py dataSourceConfig.py /work/config
RUN /work/configure.sh
```

### Logging configuration
	
By default, the Docker Hub image is using High Performance Extensible Logging (HPEL) mode and is outputing logs in JSON format. This logging configuration will make the docker container a lot easier to work with ELK stacks. 

Alternatively, user can use basic logging mode is plain text format. You can switch the logging mode to basic via the following Dockerfile:

```
FROM ibmcom/websphere-traditional:latest
ENV ENABLE_BASIC_LOGGING=true
RUN /work/configure.sh
```
    
### Running Jython scripts individually

If you have some Jython scripts that must be run in a certain order, or if they require parameters to be passed in, then you can directly call
the `/work/configure.sh` script - once for each script.  

Let's say you have 2 scripts, `configA.py` and `configB.py`, which must be run in that order.  You can configure them via the following Dockerfile:

```
FROM ibmcom/websphere-traditional:latest
COPY --chown=was:root configA.py configB.py /work/
RUN /work/configure.sh /work/configA.py <args> \
    && /work/configure.sh /work/configB.py <args>
```

### Runtime configuration

How about properties that are dynamic and depend on the environment (eg: changing JAAS passwords or data source host at runtime)?  tWAS is not nearly as dynamic as Liberty, but we have augmented the `start_server` script to look into `/etc/websphere` for any property files that need to applied to the server.

So during `docker run` you can setup a volume that mounts property files into `/etc/websphere`, such as:

```bash
docker run -v /config:/etc/websphere  -p 9043:9043 -p 9443:9443 websphere-traditional:9.0.0.9-profile
```

Similarly to build-phase props, the dynamic runtime props will also be applied in alphabetic order, so you can also use numeric prefixes to guarantee dependent props are applied in an adequate order.

## How to run this application image

When the container is started by using the IBM WebSphere Application Server traditional profile image, it takes the following environment variables:

* `UPDATE_HOSTNAME` (optional, set to `true` if the hostname should be updated from the default of `localhost`)
* `PROFILE_NAME` (optional, default is `AppSrv01`)
* `CELL_NAME` (optional, default is `DefaultCell01`)
* `NODE_NAME` (optional, default is `DefaultNode01`)
* `SERVER_NAME` (optional, default is `server1`)
* `ADMIN_USER_NAME` (optional, default is `wsadmin`)

### Running the image by using the default values
  
```bash
   docker run --name was-server -h was-server -p 9043:9043 -p 9443:9443 -d \
   websphere-traditional:9.0.0.9-profile
```

### Running the image by passing values for the environment variables

```bash
docker run --name <container-name> -h <container-name> \
  -e UPDATE_HOSTNAME=true -e PROFILE_NAME=<profile-name> \
  -e CELL_NAME=<cell-name> -e NODE_NAME=<node-name> \
  -e SERVER_NAME=<server-name> -e ADMIN_USER_NAME=<admin-user-name>\
  -p 9043:9043 -p 9443:9443 -d <profile-image-name>
```    

Example:

```bash
docker run --name test -h test -e UPDATE_HOSTNAME=true \
  -e PROFILE_NAME=AppSrv02 -e CELL_NAME=DefaultCell02 \
  -e NODE_NAME=DefaultNode02 -e SERVER_NAME=server2 \
  -e ADMIN_USER_NAME=wasadmin \
  -p 9043:9043 -p 9443:9443 -d websphere-traditional:profile 
``` 

### Retrieving the password

The admin console user id is default to ```wsadmin``` and the initial wsadmin user password is
in ```/tmp/PASSWORD```
```
   docker exec was-server cat /tmp/PASSWORD
```

### Checking the logs

```bash
docker logs -f --tail=all <container-name>
```

Example:

```bash
docker logs -f --tail=all test
``` 

The logs from this container is also available inside `/logs`, therefore you can setup a volume mount to persist these logs into an external directory:


### Stopping the Application Server gracefully

```bash
docker stop --time=<timeout> <container-name>
```

Example:

```bash
docker stop --time=60 test
```
