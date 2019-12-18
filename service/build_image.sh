sudo docker build -t taxicounterservice:0.3 .
#sudo docker run  -p 8000:8000 myimage:0.1
sudo docker login
sudo docker tag taxicounterservice:0.3 sandeepgiri9/taxicounterk8sm:service
sudo docker push sandeepgiri9/taxicounterk8sm:service
#sudo docker run -p 8000:8000 sandeepgiri9/taxicounterk8s:service

