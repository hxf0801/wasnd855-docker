# inherit wasbase's all environment variables and its CMD command
FROM wasbase

##TODO: Here you can copy specific application asset to image like below
#COPY --chown=was:root mySample /work/mySample/
#RUN /work/mySample/wasdeploy/wasdeploy_initial.sh
#RUN /work/mySample/wasdeploy/wasdeploy.sh

RUN /work/configure.sh /opt/IBM/WebSphere/AppServer/profiles/$PROFILE_NAME/bin/deployConsole.py install
