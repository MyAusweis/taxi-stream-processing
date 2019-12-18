FROM python:3.7-slim
RUN pip install google-cloud-pubsub 
ARG service_domain
WORKDIR /code
ENV GOOGLE_APPLICATION_CREDENTIALS thelab-cad070853083.json
COPY requirements.txt requirements.txt
COPY src src
WORKDIR /code/src
CMD ["python3", "main.py"]
