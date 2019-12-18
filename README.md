# Taxi Stream Processing Project - Problem statement

We would like you to build a Web Service that provides basic metrics over taxi data. The live data can be obtained from Pub/Sub at projects/pubsub-public-data/topics/taxirides-realtime. You will need to provide a simple Web service that returns the total number of trips in the past one hour. There will be no parameters for this web service.

You will need to deploy your service and dependencies on a distributed cluster of your choice. Each service you use should be running in Docker. We will be testing your deployment on a bare Ubuntu VM, so you should provide a single script (e.g., Shell or Vagrant) to set up the cluster and your services.

If you use a shell script, it should be called install.sh and it will be invoked with sudo ./install.sh from the home directory of the default user. You may let us know if your script requires additional parameters.

## Other considerations

+ We prefer Kubernetes, but you may consider Docker Swarm, Mesos, etc.
+ Your entire system should run on Ubuntu 16.04 LTS Server. We will test using a VM with 20GB of storage, 8GB of RAM, and 4 cores, but if you need more to run, please let us know.
+ The Web service should be accessible within the test VM.
+ There is no need to consider data more than one hour old.
+ It should be possible to complete this assignment within GCP’s free tier.

------

# Solution

## Installation
# Copy the installer - install.sh (located in k8s/installer folder)

    export HOST=34.67.172.150
    scp install.sh $HOST:

# Run installer
    ssh $HOST 
    ./install.sh"

# Check the output

    ssh $HOST
    export SER_IP=`kubectl get services taxiservice-main|grep taxi|awk '{print $3}'`
    curl http://$SER_IP
    # Output should look like this:
    {"counts": 469}

# To Stop

    ssh $HOST kubectl delete -k .

## Design Description

The objective is to consume the taxi rides from public pub/sub and provide a way for the user to see the total number of rides in last one hour.

For this, I have created two kinds of services:

1. A web service - which runs on only one node
2. A feed comsumer - which can run on any number of nodes


Let me provide a brief description of each.

### 1. A web service - which runs on only one node
    
It is a python-django based service. It is Using SQLLite Based Solution right.
It provides two end points one is "/" which when hitting returns the counts in the json format. The other end point is "/add-counts", user needs to make a POST request with counts. I have kept it as "POST" purpose fully to avoid repeated counts that might have occurred because of re-hitting the "GET" url.

Please note that there are two services corresponding to this in `docker-compose` file because I needed database migration/create service separately.

### 2. A feed comsumer - which can run on any number of nodes

It is a simple python script which reads data synchronously from a google pub/sub queue and publishes the counts to the main service. There can be many such consumers running in parallel.

## Further Improvements:

1. For performance, we can use Redis instead of SQL and we can further scale Redis.
2. The current service can be load balanced. 
3. For performance, we can move the Django service to either Go or Java from Python. 
4. For the performance of the service, we can use a scheduler to delete the older events. Right now, the old events are being deleted at the time of adding the counts.
5. The various values that have been hardcoded can be extracted into settings in both `counterservice` as well as `feedclient.`
6. We should write the various test (unit and mock) cases of services.
