export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt-get update
sudo apt-get -y --allow-unauthenticated install docker-ce docker-ce-cli containerd.io
sudo curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo systemctl enable docker
sudo apt-get -y install python-pip

#ip install --upgrade google-cloud-pubsub
#sudo mkdir -p /var/taxicountsite/data/

# Install Kubernetes
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl


# Install MiniKube
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 \
  && chmod +x minikube

sudo install minikube /usr/local/bin
sudo minikube  --vm-driver=none start

#sudo mv /home/$USER/.kube /home/$USER/.minikube $HOME
sudo chown -R $USER $HOME/.kube $HOME/.minikube

# Generate the configs
cat <<EOF >./kustomization.yaml
secretGenerator:
- name: mysql-pass
  literals:
  - password=HYUJ@*!@KL
resources:
  - mysql-deployment.yaml
  - taxicounter-service-deployment.yaml
  - feedconsumer-deployment.yaml
EOF

cat <<EOF >./feedconsumer-deployment.yaml
apiVersion: v1
kind: Service
metadata:
  name: feedconsumer
  labels:
    app: feedconsumer
spec:
  ports:
    - port: 80
  selector:
    app: feedconsumer
    tier: frontend
  type: LoadBalancer
---
apiVersion: apps/v1 # for versions before 1.9.0 use apps/v1beta2
kind: Deployment
metadata:
  name: feedconsumer
  labels:
    app: feedconsumer
spec:
  replicas: 4
  selector:
    matchLabels:
      app: feedconsumer
      tier: frontend
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: feedconsumer
        tier: frontend
    spec:
      containers:
      - image: sandeepgiri9/taxicounterk8s:feedconsumer
        name: feedconsumer
        env:
        - name: feedconsumer_DB_HOST
          value: feedconsumer-mysql
        - name: feedconsumer_DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-pass
              key: password        

EOF


cat <<EOF >./mysql-deployment.yaml
apiVersion: v1
kind: Service
metadata:
  name: taxiservice-mysql
  labels:
    app: taxiservice
spec:
  ports:
    - port: 3306
  selector:
    app: taxiservice
    tier: mysql
  clusterIP: None
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pv-claim
  labels:
    app: taxiservice
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
---
apiVersion: apps/v1 # for versions before 1.9.0 use apps/v1beta2
kind: Deployment
metadata:
  name: taxiservice-mysql
  labels:
    app: taxiservice
spec:
  selector:
    matchLabels:
      app: taxiservice
      tier: mysql
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: taxiservice
        tier: mysql
    spec:
      containers:
      - image: mysql:5.6
        name: mysql
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-pass
              key: password
        ports:
        - containerPort: 3306
          name: mysql
        volumeMounts:
        - name: mysql-persistent-storage
          mountPath: /var/lib/mysql
      volumes:
      - name: mysql-persistent-storage
        persistentVolumeClaim:
          claimName: mysql-pv-claim
EOF

cat <<EOF >./taxicounter-service-deployment.yaml
apiVersion: v1
kind: Service
metadata:
  name: taxiservice-main
  labels:
    app: taxiservice
spec:
  ports:
    - port: 80
  selector:
    app: taxiservice
    tier: frontend
  type: LoadBalancer
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: wp-pv-claim
  labels:
    app: taxiservice
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
---
apiVersion: apps/v1 # for versions before 1.9.0 use apps/v1beta2
kind: Deployment
metadata:
  name: taxiservice-main
  labels:
    app: taxiservice
spec:
  selector:
    matchLabels:
      app: taxiservice
      tier: frontend
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: taxiservice
        tier: frontend
    spec:
      containers:
      - image: sandeepgiri9/taxicounterk8sm:service
        name: taxiservice
        env:
        - name: taxiservice_DB_HOST
          value: taxiservice-mysql
        - name: taxiservice_DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-pass
              key: password
        ports:
        - containerPort: 80
          name: taxiservice
        volumeMounts:
        - name: taxiservice-persistent-storage
          mountPath: /var/www/html
      volumes:
      - name: taxiservice-persistent-storage
        persistentVolumeClaim:
          claimName: wp-pv-claim

EOF

cat <<EOF >./create_database.sh
echo "create database IF NOT EXISTS taxicounter;"|mysql -uroot -p\$MYSQL_ROOT_PASSWORD
echo "Databases Now: "
echo "show databases;"|mysql -uroot -p\$MYSQL_ROOT_PASSWORD
EOF

chmod +x create_database.sh



# Start
kubectl apply -k ./

kubectl get pods
echo "Waiting for MySQL service to come up..."
while [ `kubectl get pods|grep mysql|grep Running &>/dev/null; echo $?` -ne 0 ]; do echo -n ".";sleep 1; done
kubectl get pods
export TSM=`kubectl get pods|awk '{print $1}'|grep mysql`
kubectl cp create_database.sh $TSM:create_database.sh
#sleep 2;
#kubectl exec -ti $TSM -- sh ./create_database.sh
echo "Trying to create database."
while [ `kubectl exec -ti $TSM -- sh ./create_database.sh|grep taxicounter &>/dev/null;echo $?` -ne 0 ]; do echo -n ".";sleep 1; done

echo "Waiting for Django service to come up..."
while [ `kubectl get pods|grep taxiservice-main|grep Running &>/dev/null;echo $?` -ne 0 ]; do echo -n ".";sleep 1; done
kubectl get pods

sleep 2;
export TS=`kubectl get pods|awk '{print $1}'|grep taxiservice|grep -v mysql`
kubectl exec $TS -- python main/taxicountsite/manage.py migrate
kubectl exec $TS -- python main/taxicountsite/manage.py runserver 0.0.0.0:80 &>/dev/null &

cat <<EOF >./check-service.sh
export SER_IP=`kubectl get services taxiservice-main|grep taxi|awk '{print $3}'`
curl http://\$SER_IP
EOF

chmod +x ./check-service.sh

echo "Service is up. Please use the following command to see last one hour counts: ./check-service.sh"
#kubectl expose deployment taxiservice --type=LoadBalancer --name=taxiservice-main
