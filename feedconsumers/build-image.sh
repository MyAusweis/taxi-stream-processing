sudo docker build -t taxifeedconsumer:0.2 .
sudo docker login
sudo docker tag taxifeedconsumer:0.2 sandeepgiri9/taxicounterk8s:feedconsumer
sudo docker push sandeepgiri9/taxicounterk8s:feedconsumer
#sudo docker run sandeepgiri9/taxicounter:feedconsumer

