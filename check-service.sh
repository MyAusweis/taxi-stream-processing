export SER_IP=`kubectl get services taxiservice-main|grep taxi|awk '{print $3}'`
curl http://$SER_IP

