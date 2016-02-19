# docker-nrpe [![](https://badge.imagelayers.io/totem/docker-nrpe:latest.svg)](https://imagelayers.io/?images=totem/docker-nrpe:latest 'Get your own badge on imagelayers.io')
NRPE Docker Container

## About
Provides NRPE Server within docker container. This allows remote monitoring of docker hosts from nagios/Icinga.

## Status
Ready for production

## Images
The docker-nrpe image is available on docker hub [totem/docker-nrpe:latest](https://registry.hub.docker.com/u/totem/docker-nrpe). It is setup using hub's automated build process.

## Running
In order to run the NRPE container , use command :

```
docker run --privileged -v /:/mnt/ROOT --rm --name nrpe -it -p 5666:5666 totem/docker-nrpe
```

Once up, you can monitor server using nagios/icinga. 

Note: In order to monitor multiple disks, simply mount them under /mnt directory.
