# administrative console application

Install the shipped administrative console application to IBM WebSphere Application Server.

> To build with specified values:
```bash
docker build -t wasiscapp . 
```
Note: the `FROM wasbase` image itself contains the environment variables and their values: PROFILE_NAME (AppSrv01), SERVER_NAME (CITISIT), CELL_NAME (PTSit1Cell01), NODE_NAME (PTSit1Node01), ADMIN_USER_NAME (wasadmin). These values were injected when building `wasbase`. so don't need to provide any build-time arguments to build `wasiscapp` image. Finally the build results in a `wasiscapp` image which inherit `wasbase` CMD command *`"/work/start_server.sh"`* and all environment variables.

> To run the application image with default environment variables
```bash
docker run --name test -h test -e UPDATE_HOSTNAME=true \
    -p 9043:9043 -p 9443:9443 -p 9060:9060 -p 9080:9080 \
    -d wasiscapp
```

> To access application in container

enter `https://192.168.99.103:9443/HelloHTML.jsp` in browser to access the DefaultApplication application.

enter `https://192.168.99.103:9043/ibm/console` in browser to access IBM ISC application, provide the admin user/pwd to logon.

other than the browser, use terminal to connect to the container by its name:
```bash
$ docker exec -it test /bin/bash
```

Note: For nicer mintty terminal, such as Git bash, use `winpty` prefix docker exec and double slash(`//`)  for root path, like:
```bash
$ winpty docker exec -it test //bin/bash
[was@test /]$ echo $UPDATE_HOSTNAME
true
[was@test /]$ echo $(hostname)
test
[was@test /]$ exit
```