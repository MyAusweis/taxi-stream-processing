export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"

add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
apt-get update
apt-get install docker-ce docker-ce-cli containerd.io
curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
systemctl enable docker
apt-get install python-pip

#ip install --upgrade google-cloud-pubsub
mkdir -p /var/taxicountsite/data/

docker swarm init

export COMPOSE_FILE="docker-compose.yml"
cat > $COMPOSE_FILE <<- EOM
version: "3"
services:
  taxicounterservice_migration:
    image: sandeepgiri9/taxicounter:service
    volumes:
      - /var/taxicountsite/data/:/code/main/taxicountsite/data
    deploy:
      placement:
        constraints: [node.role == manager]
    networks:
      - webnet
    command: python /code/main/taxicountsite/manage.py migrate
  taxicounterservice:
    image: sandeepgiri9/taxicounter:service
    ports:
      - "80:8000"
    volumes:
      - /var/taxicountsite/data/:/code/main/taxicountsite/data
    deploy:
      placement:
        constraints: [node.role == manager]
    networks:
      - webnet
    command: python /code/main/taxicountsite/manage.py runserver 0.0.0.0:8000
    depends_on:
      - taxicounterservice_migration
  feedconsumer:
    # replace username/repo:tag with your name and image details
    image: sandeepgiri9/taxicounter:feedconsumer
    deploy:
      replicas: 4
      resources:
        limits:
          cpus: "0.1"
          memory: 50M
      restart_policy:
        condition: on-failure
    networks:
      - webnet
    depends_on:
      - taxicounterservice
networks:
  webnet:

EOM
docker stack deploy -c docker-compose.yml taxi
