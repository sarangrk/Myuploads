# Project structure
```
PAMdemo/Docker \
  -- Dockerfile
  -- pamanalyser \
    -- ...
    -- ...
  -- Readme.md
  -- shiny-server.conf
  -- shiny-server.sh
```

cd into the `PAMdemo` dir

Assuming that you have docker for mac, if not

```
$ brew cask install docker
$ brew cask install virtualbox
```
for windows - go to docker.com

# Create docker env with virtualbox driver

```
$ docker-machine create -d "virtualbox" --virtualbox-cpu-count "4" pam-env
$ docker-machine env pam-env
$ eval $(docker-machine env pam-env)
```

# There are two ways to run the app

1. Get prebuild image from docker hub

```
$ docker pull 861472724426.dkr.ecr.us-east-1.amazonaws.com/pamdemo:latest
$ docker tag 861472724426.dkr.ecr.us-east-1.amazonaws.com/pamdemo:latest pamdemo
```
The step above pulls the image from docker hub and then tags the image as generic-pam

2. Build it from scratch (this may take a while ~ 20-30mins)
```
$ docker build -t generic-pam .
```

# Run the image in deamon mode by opening 3838 port for the shiny server

```
$ docker run -dp 3838:3838 generic-pam
```

# Open the Shiny app in your browser

check the ip of the virtual machine

```
docker-machine ip pam-env
```

Copy and paste your ip into your browser and add the port to it

```
your_ip:3838/generic-pam

192.168.99.100:3838/generic-pam
```

Note: After each restart (terminal/laptop), you'll have to restart the docker machine. In this case

```
$ docker-machine start pam-env
$ docker-machine env pam-env
$ eval $(docker-machine env pam-env)
```


# General Docker Commands

## List
```
$ docker-machine ls #lists docker machines
$ docker images #lists images
$ docker ps # lists all the active containers
```

## Remove
```
$ docker-machine rm [machine name]
$ docker rmi [image ID/name]
$ docker rm [container ID/name]
```

## Mount a local drive while running the app
```
$ docker run -dp 3838:3838 -v /full/path/to/local/dir/:/src/shiny-server/generic-pam generic-pam
```

Doing this you will be able to edit your application locally and you can see the changes by refreshing your browser.

# Mainteners

Eliano Marques <eliano.marques@thinkbiganalytics.com>
David Springate <david.Springate@thikbiganalytics.com>
Niket Doshi <niket.doshi@thinkbiganalytics.com>
