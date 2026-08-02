# Étape 1 : Builder
FROM python:3.11-slim AS builder

WORKDIR /build

COPY requirements.txt .

RUN pip install \
    --no-cache-dir \
    --target=/packages \
    -r requirements.txt

# Étape 2 : Image Distroless

FROM gcr.io/distroless/python3-debian12

WORKDIR /moi

COPY --from=builder /packages /packages

COPY app.py .

ENV PYTHONPATH=/packages

EXPOSE 8080

CMD ["app.py"]

