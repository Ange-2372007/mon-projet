FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y python3 python3-pip curl

WORKDIR /moi

COPY requirements.txt .
RUN pip3 install -r requirements.txt

COPY app.py .

EXPOSE 8080

CMD ["python3", "app.py"]
