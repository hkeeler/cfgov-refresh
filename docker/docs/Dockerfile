FROM python:3.6-alpine

WORKDIR /usr/app/src

COPY requirements.txt .

RUN pip install -r requirements.txt

EXPOSE 8888

ENTRYPOINT [ "mkdocs","serve","-a","0.0.0.0:8888" ]
