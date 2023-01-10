# insecure-python-microservice
Insecure Python Flask Application For Kubernetes (EKS) deployment


To build and run the containers, follow these steps:

Build the first microservice's container:
cd into the directory containing the Flask app and the Dockerfile for the first microservice
Run the following command to build the container: docker build -t microservice1 .
Run the first microservice's container:
Run the following command to start the container: docker run -p 5000:5000 microservice1
Build the second microservice's container:
cd into the directory containing the Flask app and the Dockerfile for the second microservice
Run the following command to build the container: docker build -t microservice2 .
Run the second microservice's container:
Run the following command to start the container: docker run -p 5001:5001 microservice2
Now you can access the first microservice at http://localhost:5000 and the second microservice at http://localhost:5001. The second microservice will make a request to the first microservice and return the response it receives.

Note: Currently app uses microservice endpoint internally in the code to connect to another microservice hence docker container wont work directly
