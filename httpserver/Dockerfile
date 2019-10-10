# create webserver definition

FROM ihsbase

COPY responsefile.txt /opt/IBM/WebSphere/Toolbox/WCT/

RUN /opt/IBM/WebSphere/Toolbox/WCT/wctcmd.sh -tool pct -defLocPathname /opt/IBM/WebSphere/Plugins -defLocName loc1 -createDefinition -response /opt/IBM/WebSphere/Toolbox/WCT/responsefile.txt
