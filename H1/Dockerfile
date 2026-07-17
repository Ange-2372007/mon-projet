
FROM ubuntu:22.04@sha256:4f838adc7181d9039ac795a7d0aba05a9bd9ecd480d294483169c5def983b64d

RUN apt-get update && \
    apt-get install -y \
    python3=3.10.6-1~22.04.1 \
    python3-pip=22.0.2+dfsg-1ubuntu0.7 \
    curl=7.81.0-1ubuntu1.25

WORKDIR /moi

COPY requirements.txt .
RUN pip3 install -r requirements.txt

COPY app.py .

EXPOSE 8080

CMD ["python3", "app.py"]
