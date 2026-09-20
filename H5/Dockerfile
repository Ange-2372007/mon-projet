# Étape 1 : Builder
FROM python:3.11-slim@sha256:9534e5a8e315485d4061ed659af0fd78a284c015f9b73661b41d6bab25604534 AS builder
WORKDIR /build

COPY requirements.txt .

RUN pip install \
    --no-cache-dir \
    --target=/packages \
    -r requirements.txt
# Étape 2 : Image Distroless

FROM gcr.io/distroless/python3-debian12@sha256:2fdb05402a2cf21cf78fdb3ba4c5db167241e9e498140f5bf689d7efb773731f
WORKDIR /moi

COPY --from=builder /packages /packages

COPY app.py .

ENV PYTHONPATH=/packages

EXPOSE 8080

USER 65532:65532

CMD ["app.py"]

