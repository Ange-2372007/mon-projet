# =============================================================================
# H4 - Image distroless
#
# A FAIRE AVANT DE CONSTRUIRE : epingler les DEUX images de base par digest.
# Sans cela, l'acquis de l'etape H1
# est perdu.
#
# -----------------------------------------------------------------------------
# ETAPE 1 - DANS LE TERMINAL
# Se placer a la racine du projet.
#
# 1a. Premiere image (le builder, ligne FROM n1) :
#
#   docker pull python:3.11-slim
#   docker image inspect python:3.11-slim --format='{{index .RepoDigests 0}}'
#
#     -> affiche par exemple : python@sha256:1a2b3c4d...
#     -> copier la partie qui commence a "sha256:"
#     -> c'est le DIGEST N1
#
# 1b. Seconde image (l'image distroless, ligne FROM n2) :
#
#   docker pull gcr.io/distroless/python3-debian12
#   docker image inspect gcr.io/distroless/python3-debian12 --format='{{index .RepoDigests 0}}'
#
#     -> affiche par exemple : gcr.io/distroless/python3-debian12@sha256:9f8e7d6c...
#     -> copier la partie qui commence a "sha256:"
#     -> c'est le DIGEST N2
#
#
# -----------------------------------------------------------------------------
# ETAPE 2 - DANS CE FICHIER
# Deux remplacements a faire, un par ligne FROM :
#
#   ligne FROM n1  ->  remplacer COLLER_DIGEST_N1 par le DIGEST N1
#   ligne FROM n2  ->  remplacer COLLER_DIGEST_N2 par le DIGEST N2
#
# Puis sauvegarder.
#
# -----------------------------------------------------------------------------
# ETAPE 3 - DANS LE TERMINAL
# Verifier que l'epinglage fonctionne :
#
#   docker build --pull -t projet:h4 ./H4
#   ./tester.sh projet:h4
#
# =============================================================================


# --- Etage 1 : le builder ------------------------------------------------

# LIGNE FROM N1 - y coller le DIGEST N1
FROM python:3.11-slim@sha256:9534e5a8e315485d4061ed659af0fd78a284c015f9b73661b41d6bab25604534 AS builder
WORKDIR /build

COPY requirements.txt .


RUN pip install \
    --no-cache-dir \
    --target=/packages \
    -r requirements.txt


# LIGNE FROM N2 - y coller le DIGEST N2
FROM gcr.io/distroless/python3-debian12@sha256:2fdb05402a2cf21cf78fdb3ba4c5db167241e9e498140f5bf689d7efb773731f


WORKDIR /moi


COPY --from=builder /packages /packages
COPY app.py .


ENV PYTHONPATH=/packages

EXPOSE 8080


CMD ["app.py"]
