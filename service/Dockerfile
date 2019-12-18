FROM python:3.7
WORKDIR /code
COPY main/requirements.txt requirements.txt
RUN pip install -r requirements.txt
COPY main main
RUN mkdir -p main/taxicountsite/data
#RUN python main/taxicountsite/manage.py migrate
CMD tail -f /dev/null
#CMD ["python", "main/taxicountsite/manage.py", "runserver", "0.0.0.0:80"]
