1.Titre
#
Durcissement et signature d'images docker
Projet de durcissement d'images Docker reposant sur l'application progressive de techniques de sécurisation et de signature .

2. Objectif

#
Évaluer l'impact de chaque étape de durcissement sur la sécurité d'une image Docker en mesurant la réduction des vulnérabilités, la diminution de la taille de l'image et en garantissant son intégrité et son authenticité grâce aux mécanismes de signature.

3. Technologies 
 #
 -Docker: connstruction d'images
 -Python:Developpement de l'application
 -Trivy:Analyse des vulnerabilites des images
 -Bash:Automatisation des taches
 -Git:Gestion des versions
 -Flask:Application web de demonstration
 -jq:Extraction des metriques depuis les rapports json


4. Structure du projet
  ## 📁 Structure du projet


.
├── H0/
│   ├── Dockerfile
│   ├── app.py
│   └── requirements.txt
├── H1/
│   ├── Dockerfile
│   ├── app.py
│   └── requirements.txt
├── H2/
│   ├── Dockerfile
│   ├── app.py
│   └── requirements.txt
├── resultats/
│   ├── rapport_H0.json
│   ├── rapport_H1.json
│   └── rapport_H2.json
├── collecter.sh
├── evolution.csv
└── README.md
Chaque dossier `Hx` représente une étape du processus de durcissement de l'image Docker. Les résultats des analyses de vulnérabilités sont stockés dans le dossier `resultats`, à travers le script de collecte `collecter.sh`, qui automatise l'analyse de chaque image Docker.

Le fichier `evolution.csv`, quant à lui, centralise les principales métriques issues des analyses de vulnérabilités, notamment la taille de l'image, le nombre de paquets installés ainsi que le nombre de vulnérabilités classées par niveau de sévérité.

5. Etapes de durcissement 
  #
  a.H0

L'étape H0 consiste à créer une image de référence qui servira de point de comparaison pour l'ensemble des étapes de durcissement.

Cette image est construite à partir de l'image de base `ubuntu:22.04` et intègre une application Web Flask de démonstration ainsi que les dépendances nécessaires à son exécution (`Python`, `pip` et `curl`).


   b.H1
Cette etape consiste a figer les versions des composants afin de garantir la reproductibilite du build.Elle introduit l'utilisation du digest pour l'image de base ubuntu:22.04 et fixe les versions de python,pip,et curl.Chaque reconstruction de l'image s'appuie donc sur les meme versions de composants,garantissant des resultats reproductibles et coherents.


    c.H2

Cette étape consiste à remplacer l'image de base `ubuntu:22.04` par l'image officielle `python:3.12-slim`. Déjà équipée de `Python` et `pip`, cette image est particulièrement adaptée à l'exécution d'une application Flask.

Le choix de cette image permet de réduire considérablement la taille de l'image Docker ainsi que le nombre de paquets installés. Par conséquent, la surface d'attaque est réduite, ce qui entraîne une diminution significative du nombre de vulnérabilités détectées.


6. Resultats

#H0
- Taille de l'image : 201.22 Mo
- Nombre de paquets : 246
- Total des vulnérabilités : 2892

#H1
- Taille de l'image : 203.85 Mo
- Nombre de paquets : 246
- Total des vulnérabilités : 2707

#H2
- Taille de l'image : 45.92 Mo
- Nombre de paquets : 95
- Total des vulnérabilités : 142

7.Analyse des resultats


L'analyse de ces résultats montre qu'au cours des différentes étapes de durcissement, il y a eu une diminution progressive de la taille de l'image, du nombre de paquets installés et du nombre de vulnérabilités détectées.

Ces résultats montrent que le choix d'une image de base adaptée constitue une mesure efficace pour améliorer la sécurité d'une image Docker. En effet, plus une image est légère et contient uniquement les composants nécessaires, moins elle présente de surface d'attaque et de vulnérabilités potentielles.


#Auteur

**Ange Yasmir Fouodji Djouda **

- GitHub : https://github.com/Ange-2372007

- Projet :
https://github.com/Ange-2372007/mon-projet
