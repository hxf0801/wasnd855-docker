# change Docker machine location on windows7
By default, the docker machine creates its VM at `C:\Users\username\.docker\machine\machines\default`. Since there is limited disk space on the C drive, so we move the folder as desired.

1. Setup the MACHINE_STORAGE_PATH environment variable as the root of the location you want to use for the Docker machines/VMs, cache, etc. 

```shell
MACHINE_STORAGE_PATH=d:\ws-docker-env
```

2. Install Docker Toolbox.

3. Run Docker Quickstart Terminal.

Docker Toolbox will now create all the files at the location pointed at by MACHINE_STORAGE_PATH.



# basic operations
```shell
$ docker-machine ls
$ docker-machine start default
$ docker-machine env
$ eval $(docker-machine env)
$ docker-machine stop default

$ docker volume ls
$ docker network ls
$ docker network prune
$ docker network --help

# delte VM
$ docker-machine rm default

# creating a docker VM 'default' with specified disk size
$ docker-machine create -d virtualbox --virtualbox-memory "8192" --virtualbox-disk-size "100000" default
```

If running into the below error when running docker command:
```shell
error during connect: Post https://192.168.99.102:2376/v1.37/build?buildargs=%7B%22HTTPS_PROXY%22%3A%22http%3A%2F%2Farchive.ubuntu.com%2Fubuntu%2F%22%2C%22HTTP_PROXY%22%3A%22http%3A%2F%2Farchive.ubuntu.com%2Fubuntu%2F%22%2C%22NO_PROXY%22%3A%22127.0.0.1%2Clocalhost%22%2C%22http_proxy%22%3A%22http%3A%2F%2Farchive.ubuntu.com%2Fubuntu%2F%22%2C%22https_proxy%22%3A%22http%3A%2F%2Farchive.ubuntu.com%2Fubuntu%2F%22%2C%22no_proxy%22%3A%22127.0.0.1%2Clocalhost%22%7D&cachefrom=%5B%5D&cgroupparent=&cpuperiod=0&cpuquota=0&cpusetcpus=&cpusetmems=&cpushares=0&dockerfile=Dockerfile.prereq&labels=%7B%7D&memory=0&memswap=0&networkmode=default&rm=1&session=13f0f5efb1e0e3976a179b0c056b09abf2bf6bfc381e60183319398589697491&shmsize=0&t=was8559_ubuntu1804&target=&ulimits=null: dial tcp 192.168.99.102:2376: connectex: A connection attempt failed because the connected party did not properly respond after a period of time, or established connection failed because connected host has failed to respond.
```
then run ```eval $(docker-machine env)``` to configure your shell



# correct docker run command in windows

Be aware run it with additional **/** for volume like:
```docker run -d --name simple2 -v /c/Users/src://usr/share/nginx/html -p 8082:80 ng1```
Or even for host OS, as
```docker run -d --name simple2 -v //c/Users/src://usr/share/nginx/html -p 8082:80 ng1```

The above command is to bind local windows file system folder _c:\Users\src_ to the VM file system path _/usr/share/nginx/html_. But we need the additional slash due to this below issue:
> This is something that the MSYS environment does to map POSIX paths to Windows paths before passing them to executables.

# docker mount vs docker volume
The --mount and -v examples below produce the same result:
```
$ docker run -d \
  -it \
  --name devtest \
  --mount type=bind,source="$(pwd)"/target,target=/app \
  nginx:latest
```

```
$ docker run -d \
  -it \
  --name devtest \
  -v "$(pwd)"/target:/app \
  nginx:latest
```
Look for the Mounts section:
```

The Mount section of the result of running "docker inspect":
"Mounts": [
    {
        "Type": "bind",
        "Source": "/tmp/source/target",
        "Destination": "/app",
        "Mode": "",
        "RW": true,
        "Propagation": "rprivate"
    }
],
```

# notes on how to write dockerfile

_COPY_ command to copy local file to the container with default _root_ privilege. To use option *--chown* to specify user and group when copying file.
```COPY --chown=$user:$group InstalMgr1.6.2_LNX_X86_64_WAS_8.5.5.zip /tmp/IM.zip```


# transfer Docker image from one machine to another one without using a repository

You will need to save the Docker image as a tar file:
```sh
    docker save -o <path for generated tar file> <image name>
```

Then copy your image to a new system with regular file transfer tools such as cp, scp or rsync(preferred for big files). After that you will have to load the image into Docker:
```sh
    docker load -i <path to image tar file>
```
PS: You may need to __sudo__ all commands.

EDIT: You should add filename (not just directory) with -o, for example:
    docker save -o c:/myfile.tar centos:16
    docker load -i myfile.tar


# Copying files from Docker container to host

In order to copy a file from a container to the host, you can use the command
```sh
docker cp <containerId>:/file/path/within/container /host/path/target
```
Here's an example:
```
$ sudo docker cp goofy_roentgen:/out_read.jpg .
```
Here *goofy_roentgen* is the name I got from the following command:
```
$ sudo docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS                                            NAMES
1b4ad9311e93        bamos/openface      "/bin/bash"         33 minutes ago      Up 33 minutes       0.0.0.0:8000->8000/tcp, 0.0.0.0:9000->9000/tcp   goofy_roentgen
```

# Copying files from host to Docker container

The cp command can be used to copy files.

1. Get container name or short container id:
```sh
    $ docker ps
```

2. Get full container id:
```sh
    $ docker inspect -f   '{{.Id}}'  SHORT_CONTAINER_ID-or-CONTAINER_NAME
```

3. Copy file:
```sh
    $ sudo cp path-file-host /var/lib/docker/aufs/mnt/FULL_CONTAINER_ID/PATH-NEW-FILE
```

4. samples

- One specific file can be copied TO the container like:
```
    docker cp foo.txt mycontainer:/foo.txt
```

- One specific file can be copied FROM the container like:
```
    docker cp mycontainer:/foo.txt foo.txt
```
For emphasis, *mycontainer* is a __container ID__, not an image ID.

- Multiple files contained by the folder src can be copied into the target folder using:
```
    docker cp src/. mycontainer:/target
    docker cp mycontainer:/src/. target
```

# how to copy docker volume to local

> To copy data from the volume to the host, use a temporary container that has the volume mounted.
```bash
CID=$(docker run -d -v hello:/hello busybox true)
docker cp $CID:/hello ./
```

> To copy a directory from the host to volume
```bash
cd local_dir
docker cp . $CID:/hello/
```

> Then clean up the temporary container.
```bash
docker rm $CID
```

# how to explore a file system of a docker build

Everytime docker successfully executes a RUN command from a Dockerfile, a new layer in the image filesystem is committed. Conveniently you can use those layers ids as images to start a new container.

Take the following output of building a Dockerfile:
```
......
Step 6/21 : RUN groupadd $group     && useradd $user -g $group -m    && chown -R $user:$group /var /opt /tmp
 ---> Running in 02fa1d5133e6
Removing intermediate container 02fa1d5133e6
 ---> f049f56052c0
Step 7/21 : USER $user
 ---> Running in 032ddcc8135d
Removing intermediate container 032ddcc8135d
 ---> f73d3bca2e1a
Step 8/21 : COPY InstalMgr1.6.2_LNX_X86_WAS_8.5.5.zip /tmp/IM.zip
 ---> d1d552752ae0
Step 9/21 : RUN  mkdir /tmp/im && unzip -qd /tmp/im /tmp/IM.zip     && /tmp/im/installc -acceptLicense -accessRights nonAdmin       -installationDirectory "/opt/IBM/InstallationManager"        -dataLocation "/var/ibm/InstallationManager" -showProgress     && rm -fr /tmp/IM.zip /tmp/im
 ---> Running in dc25283f4411
/bin/sh: 1: /tmp/im/installc: not found
The command '/bin/sh -c mkdir /tmp/im && unzip -qd /tmp/im /tmp/IM.zip     && /tmp/im/installc -acceptLicense -accessRights nonAdmin       -installationDirectory "/opt/IBM/InstallationManager"        -dataLocation "/var/ibm/InstallationManager" -showProgress     && rm -fr /tmp/IM.zip /tmp/im' returned a non-zero code: 127
```

Using these images **_f049f56052c0_**, **_f73d3bca2e1a_** and **_d1d552752ae0_**, you can now start a shell in a new container to explore the filesystem and try out commands:
```
$ docker run --rm -it d1d552752ae0 sh 
```

Type command in the shell to list _/tmp_:
```
ls -l /tmp
total 128740
-rwxr-xr-x 1 root root 131826308 Jan 13  2014 IM.zip
```

In case of the Dockerfile command failing, in order to debug the failure, what you need to do is to look for the **id of the preceding layer** and run a shell in a container created from that id:
- find the container that failed:
    ```
    $ docker ps -a

    CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                        PORTS               NAMES
    dc25283f4411        d1d552752ae0        "/bin/sh -c 'mkdir /…"   21 minutes ago      Exited (127) 21 minutes ago                       exciting_poincare
    ```

- And then run the image in bash shell or default shell:
    ```
    $ docker run --rm -it d1d552752ae0 bash -il
    $ docker run --rm -it d1d552752ae0 sh 
    ```
    > If you see the warning: the input device is not a TTY.  If you are using mintty, try prefixing the command with 'winpty'. Try: 
    ```
    $ winpty docker run --rm -it wasnd855-custom:centos7 bash -il
    ```

- noteworthly, the below command can commit a container to an image if necessary:
    ```
    $ docker commit dc25283f4411
    sha256:d93a59bf1085103e3d82b434235ee37e08298e391e5318ffcef8ed6a47a80f8c
    ```

    Now you are actually looking at the state of the build at the time that it failed if you explore the newly created image _d93a59bf1085_, instead of at the time before running the command that caused the failure.

```
docker container run --rm -it \
  -v $(app):/app \                          # Mount the source code
  --workdir /app \                          # Set the working dir
  --user 1000:1000 \                        # Run as the given user
  my-docker/my-build-environment:latest \   # Our build env image
  make assets                               # ... and the command!
```

# Stop/start separate containers with compose
An important notice is that you should use docker-compose to stop/remove/start the containers. When you don't use docker-compose, the name will be generated by docker and the container will not be part of the 'compose stack' anymore.

> To stop a specific container, use the following command:
```
$ docker-compose -f <<path to docker-compose.yml>> stop engine1
```

> To remove a specific container, use this command:
```
$ docker-compose -f <<path to docker-compose.yml>> remove engine1
```

> To start a specific container (in detach mode), use this command:
```
$ docker-compose -f <<path to docker-compose.yml>> up -d engine1
```

> Run the following command:
```
$ docker-compose -f <<path to docker-compose.yml>> logs
```
This command will output all the logs since the container has been created.

> Run the following command:
```
$ docker-compose -f <<path to docker-compose.yml>> logs <<name of the service>>
```
This command will print logs for certain services. You can obtain the service name from the compose file.

> Completely stop, delete compose stack
```
$ docker-compose -f <<path to docker-compose.yml>> down
```

> Completely build, start compose stack, leave them running
```
$ docker-compose -f <<path to docker-compose.yml>> up -d
```

# SSH into a Container
1. Use docker ps to get the name of the existing container.
2. Use the command `docker exec -it <container name> /bin/bash` to get a bash shell in the container.
3. Generically, use `docker exec -it <container name> <command>` to execute whatever command you specify in the container.