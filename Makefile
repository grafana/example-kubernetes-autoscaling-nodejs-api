all: help

help:
	@echo ----------------------------------
	@echo CROCODILE API DEPLOYMENT COMMANDS
	@echo ----------------------------------
	@echo make image 	- build and upload docker image to minikube environment
	@echo make apply 	- deploy crocodile-api and expose service
	@echo make test 	- test deployment
	@echo make delete	- uninstall crocodile-api deployment and service

delete:
	kubectl delete service crocodile-service
	kubectl delete deployment crocodile-api

image:
	eval $(minikube docker-env)
	docker image prune -f
	docker build -t brandiqa/crocodile-api .

apply:
	kubectl apply -f deploy/crocodile-deployment.yml
	kubectl get services | grep crocodile

test:
	curl 10.98.55.109:4000/crocodiles

run:
	HOSTNAME=10.98.55.109:4000/crocodiles k6 run -o influxdb=http://localhost:8086/k6 performance-test.js
