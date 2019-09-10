# Build an IBM WebSphere Application Server Network Deployment traditional image

Use Dockerfiles in directory `install` to create WAS ND 8.5.5.x Docker image. 
* `Dockerfile` is for _Ubuntu 18.04_;
* `centos7.Dockerfile` is for _CentOS 7_.

## Prerequisite
* A runable Docker environment
    * Install Docker tools. This lab uses docker 1.18.03. The installation will bring docker client and docker server.
    * Open a command line interface, such as Git Bash, command prompt, powershell, bash, etc. Run commands in order to set up a shell environment.
        ```bash
        $ docker-machine ls
        $ docker-machine start default
        $ docker-machine env
        $ eval $(docker-machine env)
        ```

        Afterwards, you can run some common commands in this shell:
        ```
        $ docker version
        $ docker image ls
        $ docker container ls
        $ docker ps -a
        $ docker container rm dmgr
        ```

* IBM Installation Manager binaries:
    * InstalMgr1.6.2_LNX_X86_64_WAS_8.5.5.zip (CIK2GML)

* IBM WebSphere Application Server Network Deployment traditional V8.5.5 binaries:
    * WAS_ND_V8.5.5_1_OF_3.zip (CIK2HML)
    * WAS_ND_V8.5.5_2_OF_3.zip (CIK2IML)
    * WAS_ND_V8.5.5_3_OF_3.zip (CIK2JML)

  Fixpack V8.5.5.x binaries:
    * 8.5.5-WS-WAS-FP0000010-part1.zip
    * 8.5.5-WS-WAS-FP0000010-part2.zip

  IBM WebSphere SDK Java Technology Edition V7.1.3.0 binaries:
    * 7.1.3.60-WS-IBMWASJAVA-part1.zip
    * 7.1.3.60-WS-IBMWASJAVA-part2.zip

## Explanation to Dockerfile
An IBM WebSphere Application Server Network Deployment traditional install image is created in a multi-stage dockerfile to reduce the final image size. The point is to reuse the result previously executed as a kind-of-starting-point rather than keeping all previous traces.

> Dockerfile takes the following actions:
* Installs IBM Installation Manager
* Installs IBM WebSphere Application Server 
* Updates IBM WebSphere Application Server with the Fixpack
* Copy the WebSphere installation directory from the intermidiary image to the final image, so that the final image does not need to contain each layer for the previous step.

> Dockerfile takes the values for the following variables at build time: 
- user (optional, default is 'wasadmin') - user used for the installation
- group (optional, default is 'wasadmin') - group the user belongs to
    
## Building the image
* Go to the directory `install`, place the downloaded binaries on the folder.
* Build the prereq image by using:
    ```bash
    docker build --build-arg user=<user> --build-arg group=<group> -t <prereq-image-name> -f Dockerfile .
    ```

    Example:

    ```bash
    docker build -t wasnd855:ubuntu1804 .
    docker build -t wasnd855:ubuntu1804 -f Dockerfile .
    docker build -t wasnd855:centos7 -f centos7.Dockerfile .
    ```

## Check the image
```
$ docker run --rm -it wasnd855:centos7 bash -il
```
> If you see the warning: **_the input device is not a TTY.  If you are using mintty, try prefixing the command with 'winpty'_**. Try: 
```
$ winpty docker run --rm -it wasnd855-custom:centos7 bash -il
```

# Build an IBM WebSphere Application Server Network Deployment traditional deployment manager image

An IBM WebSphere Application Server Network Deployment deployment manager image can be built by extending the above created Network Deployment install image. This step uses the default Dockerfile in directory `dmgr`. 

The Dockerfile takes the values for the following variables at build time:
* CELL_NAME (optional, default is 'DefaultCell01') - cell name
* NODE_NAME (optional, default is 'DefaultNode01') - node name
* PROFILE_NAME (optional, default is 'Dmgr01') - profile name
* HOST_NAME (optional, default is 'dmgr') - host name
* user (optional, default is 'wasadmin') - user to start the deployment manager instance

The Dockerfile takes the following actions:
* Uses the `wasnd855` install image as a base image
* Creates a deployment manager profile
* Exposes the required ports
* Copies the startup script to the image
* When the container is started the deployment manager is started

## Building deployment manager image

* Move to the directory `dmgr`
* Build the deployment manager image by using:
    ```bash
    docker build -t <dmgr-image-name> .
    ```

    Example: 
    
    ```bash
    docker build -t wasnd855-dmgr:ubuntu1804 .
    docker build -t wasnd855-dmgr:centos7 -f centos7.Dockerfile .
    ```

## Running deployment manager image

* Create a docker network for the Network Deployment cell topology by using:
   ```bash
   docker network create <network-name>
   ```

   This command creates a user defined bridge network, to create an overlay network, see [Get started with multi-host networking docker documentation](https://docs.docker.com/engine/userguide/networking/get-started-overlay/).

   Example:

   ```bash
   docker network create cell-network
   ```

* Run the deployment manager image by using:
   ```bash
   docker run --name <container-name> -h <container-name> --network=<network-name> -p 9060:9060 -d <dmgr-image-name>

   docker run --name <container-name> --hostname <container-name> --network=<network-name> --publish 9060:9060 --detach <dmgr-image-name>
   ```

   Example:
   ```bash
   docker run --name dmgr --hostname dmgr --network=cell-network --publish 9060:9060 --detach wasnd855-dmgr:ubuntu1804

   docker run --name dmgr --hostname dmgr --network=cell-network --publish 9060:9060 --detach wasnd855-dmgr:centos7
   ```

## Accessing the administrative console provided by the Integrated Solutions Console
* get `DOCKER_HOST` by run `docker-machine ls`
* Open `http://<DOCKER_HOST>:9060/admin`
* Security is off, so use whatever login name you like.

# Build an IBM WebSphere Application Server Network Deployment traditional custom node image

Now that the step uses Dockerfile in directory `custom` to create an IBM WebSphere Application Server Network Deployment custom node image by extending the previous Network Deployment install image.

The Dockerfile takes the values for the following variables at build time:
* CELL_NAME (optional, default is 'CustomCell') - cell name
* NODE_NAME (optional, default is 'CustomNode') - node name
* PROFILE_NAME (optional, default is 'Custom01') - profile name
* HOST_NAME (optional, default is 'localhost') - host name
* user (optional, default is 'wasadmin') - user to start the deployment manager instance

The Dockerfile takes the following actions:
* Uses the `wasnd855` install image as a base image
* Creates a custom node profile
* Exposes the required ports
* Copies the update scripts to the image
* When the container is started, the node is federated to the deployment manager and the nodeagent is started

## Building custom node image

* Move to the directory `custom`
* Build the custom node image by using:
    ```bash
    docker build -t <customnode-image-name> .
    ```

    Example: 
    ```bash
    docker build -t wasnd855-custom:ubuntu1804 .
    docker build -t wasnd855-custom:centos7 -f centos7.Dockerfile .
    ```

## Running custom node image

* Create a docker network if not exists.
* Start deployment manager if it is not started. See the above to run deployment manager image.
* Running the custom node image as follows
    * Running the custom node image by using the default values:
        ```bash
        docker run --name <container-name> -h <container-name> --network=<network-name> -d <customnode-image-name>
        ```

        Example:
        ```bash
        docker run --name custom1 -h custom1 --network=cell-network -d wasnd855-custom:ubuntu1804

        docker run --name custom1 -h custom1 --network=cell-network -d wasnd855-custom:centos7
        ```

    * Running the Custom Node image by passing values for the environment variables:
        ```bash
        docker run --name <container-name> -h <container-name> --network=<network-name> -e PROFILE_NAME=<profile-name> -e NODE_NAME=<node-name> -e DMGR_HOST=<dmgr-host> -e DMGR_PORT=<dmgr-port> -d <customnode-image-name>
        ```

        Example:
        ```bash
        docker run --name custom1 -h custom1 --network=cell-network -e PROFILE_NAME=Custom01 -e NODE_NAME=CustomNode01 -e DMGR_HOST=dmgr -e DMGR_PORT=8879 -d wasnd855-custom:ubuntu1804

        docker run --name custom1 -h custom1 --network=cell-network -e PROFILE_NAME=Custom01 -e NODE_NAME=CustomNode01 -e DMGR_HOST=dmgr -e DMGR_PORT=8879 -d wasnd855-custom:centos7
        ```

## How do I access it?

As of now, the only way to verify the custom profile is running is to create a cluster in console and try to add one member, at this moment, you will see the newly created custom node availabe in the dropdown list.