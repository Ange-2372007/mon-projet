FROM python:3.11-alpine

WORKDIR /app

COPY requirements.txt .

RUN pip install \
    --no-cache-dir \
    -r requirements.txt

COPY app.py .

USER 65532:65532

EXPOSE 8080

CMD ["python", "app.py"]
