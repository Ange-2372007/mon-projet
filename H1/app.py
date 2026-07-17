from flask import Flask

app = Flask(__name__)


@app.route("/")
def accueil():
    return "Projet C4 - Application web fonctionnelle\n"


@app.route("/health")
def health():
    return {"status": "ok"}


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
