Pipeline de durcissement d'images de conteneur et
attestation de la chaîne d'approvisionnement

Présentation du projet

Ce projet a pour objectif de mettre en place une chaîne progressive de
durcissement d'une image Docker, de mesurer l'effet de chaque étape sur
la taille, le nombre de paquets et les vulnérabilités détectées, puis de
sécuriser la chaîne d'approvisionnement de l'image finale.

Le travail est réalisé en plusieurs étapes successives, de H0 à H7.
Chaque étape introduit une technique d'optimisation ou de sécurisation
et est validée avec les mêmes outils de test et de collecte afin de
permettre une comparaison reproductible.

Le projet couvre également :

-   la génération d'un SBOM avec Syft ;
-   la signature et la vérification d'un artefact avec Cosign ;
-   un test contrôlé de détection d'altération ;
-   une analyse de bonnes pratiques avec Dockle ;
-   une comparaison entre une base Alpine et une base
    Distroless.

1.  Objectifs

Les principaux objectifs du projet sont :

1.  construire une image Docker initiale fonctionnelle et volontairement
    non durcie ;

2.  automatiser la collecte des mesures de sécurité ;

3.  appliquer progressivement les étapes de durcissement H0 à H7 ;

4.  mesurer l'évolution de la taille, des paquets et des vulnérabilités
    ;

5.  produire un SBOM de l'image finale ;

6.  signer et vérifier les artefacts ;

7.  démontrer la détection d'une altération ;

8.  analyser les bonnes pratiques de l'image finale ;

9.  comparer Alpine et Distroless.

10. Outils utilisés

  Outil et Utilisation
  
  -Docker    :     Construction et exécution des images
  -Trivy 0.71.1 :  Analyse des vulnérabilités et collecte des mesures
  -Syft 1.51.0  :  Génération du SBOM
  -Cosign 3.1.3  : Signature et vérification des artefacts
  -Dockle        : Analyse des bonnes pratiques de l'image finale
  -Bash         :  Scripts `tester.sh` et `collecter.sh`

3.  Organisation du projet

Les principaux éléments utilisés dans le projet sont organisés autour
des étapes de durcissement et des fichiers de preuve.

.
├── H0/
├── H1/
├── H2/
├── H3/
├── H4/
├── H5/
├── H7/
├── Alpine/
├── resultats/
│   ├── rapport_H0.json
│   ├── rapport_H1.json
│   ├── rapport_H2.json
│   ├── rapport_H3.json
│   ├── rapport_H4.json
│   ├── rapport_H5.json
│   ├── rapport_H7.json
│   └── rapport_ALPINE.json
├── collecter.sh
├── tester.sh
├── evolution.csv
├── sbom-h7.json
├── sbom-h7.bundle
├── README.md
└── ...


****Remarque : H6 correspond à une configuration d'exécution en
lecture seule. Il n'existe donc pas nécessairement d'image `projet:h6`
ni de `H6/Dockerfile`. L'image `projet:h5` est réutilisée avec l'option `--read-only`.

Certains fichiers de travail sensibles ou temporaires ne doivent pas
être versionnés, notamment :


cosign.key
sbom-h7-modifie.json
local-signing-config.json
H7-modifie/
evolution_ancien.csv

Ils sont exclus du dépôt avec `.gitignore` lorsqu'ils sont présents
localement.

4.  Construction de la chaîne H0 à H7

H0 :Image initiale non durcie

a.  Objectif

H0 représente l'état initial de l'application avant l'application des
techniques de durcissement. Cette étape sert de référence pour mesurer
l'effet des optimisations et des mécanismes de sécurité appliqués par la
suite.

b.  Implémentation

Pour établir une référence, nous avons construit l'image Docker initiale
sans appliquer les mesures de durcissement étudiées dans les étapes
suivantes. Cette image contient l'application et son environnement de
départ. Nous avons ensuite vérifié que l'application fonctionnait
correctement, puis lancé la collecte automatisée afin d'obtenir les
premières mesures de taille, de paquets et de vulnérabilités.


docker build -t projet:h0 H0/
./tester.sh projet:h0
./collecter.sh projet:h0 H0


c. Résultats obtenus

-   Taille : 723,52 Mo
-   Paquets : 246
-   Vulnérabilités : 4910
-   Critical : 24
-   High : 305
-   Medium : 4111
-   Low : 470
-   Unknown : 0
-   Digest :
    `sha256:cc5426e2313bbe70f89f693ac22461e04180ebdee76f64523f4eea58437477f8`

d. Analyse des résultats

Ces résultats constituent le point de référence du projet. L'image
initiale est relativement volumineuse, contient 246 paquets et présente
4 910 vulnérabilités détectées. Les étapes suivantes permettront de
mesurer précisément l'effet du durcissement.

H1 :Versions épinglées

a.  Objectif

H1 vise principalement à améliorer la reproductibilité de la
construction en fixant explicitement les versions utilisées.

b.  Implémentation

À cette étape, nous avons fixé les versions des composants et
dépendances utilisés afin de rendre la construction de l'image plus
reproductible. L'image a ensuite été reconstruite à partir du
`Dockerfile` de H1. Pour pouvoir comparer les résultats avec H0 dans des
conditions similaires, nous avons vérifié le fonctionnement de
l'application et réutilisé le même script de collecte.


docker build -t projet:h1 H1/
./tester.sh projet:h1
./collecter.sh projet:h1 H1


c. Résultats obtenus

-   Taille : 735,95 Mo
-   Paquets : 246
-   Vulnérabilités : 4724
-   Critical : 11
-   High : 286
-   Medium : 3971
-   Low : 456
-   Unknown : 0
-   Digest :
    `sha256:54391585ef635a52f5c20c6c2cbbcdb246a2850a8cf4777ebd98f4c41a40728a`

d. Analyse des résultats

Cette étape vise principalement la reproductibilité et non la réduction
de la taille. Le nombre de paquets reste identique à H0, tandis que le
nombre total de vulnérabilités passe de 4 910 à 4 724.

H2 :Base minimale / Slim

a.  Objectif

H2 vise à réduire la surface d'attaque et la taille de l'image en
remplaçant la base précédente par une image Python Slim.

b.  Implémentation

Pour H2, nous avons remplacé l'image de base précédente par une base
Python Slim, plus minimale. Cette modification vise à retirer une partie
des composants système qui ne sont pas nécessaires à l'exécution de
l'application. Après avoir adapté le `Dockerfile`, nous avons construit
la nouvelle image, testé les routes de l'application et relancé la
collecte automatisée.


docker build -t projet:h2 H2/
./tester.sh projet:h2
./collecter.sh projet:h2 H2

c. Résultats obtenus

-   Taille : 188,01 Mo
-   Paquets : 95
-   Vulnérabilités : 278
-   Critical : 3
-   High : 84
-   Medium : 104
-   Low : 86
-   Unknown : 1
-   Digest :
    `sha256:eca5cf9cf9e1e108a3d3778c32afd0a023543fa1c03dc92da6c1eb234ceac470`

d. Analyse des résultats

H2 produit l'une des réductions les plus importantes du projet. La
taille passe de 735,95 Mo à 188,01 Mo, le nombre de paquets de 246 à 95
et le nombre total de vulnérabilités de 4 724 à 278.

H3 --- Construction multi-stage

a.  Objectif

H3 vise à séparer les composants nécessaires à la construction de ceux
réellement nécessaires à l'exécution de l'application.

b.  Implémentation

Dans H3, nous avons adopté une construction multi-stage afin de séparer
l'environnement utilisé pour préparer l'application de l'image destinée
à son exécution. Seuls les éléments nécessaires au fonctionnement final
sont conservés dans l'étape finale, ce qui évite d'y inclure inutilement
certains outils de construction. L'image a ensuite été testée et
analysée avec les mêmes scripts que les étapes précédentes.


docker build -t projet:h3 H3/
./tester.sh projet:h3
./collecter.sh projet:h3 H3

c. Résultats obtenus

-   Taille : 175,62 Mo
-   Paquets : 95
-   Vulnérabilités : 278
-   Critical : 3
-   High : 84
-   Medium : 104
-   Low : 86
-   Unknown : 1
-   Digest :
    `sha256:aa925ff383852dcae73acdabbbe57b549c2a51db4baec1d820c13f7806ab3819`

d. Analyse des résultats

Le multi-stage réduit encore la taille de l'image, de 188,01 Mo à 175,62
Mo, tout en conservant 95 paquets et 278 vulnérabilités. Il permet
surtout d'éviter de conserver dans l'image finale les outils propres à
la phase de construction.

H4 :Distroless

a.  Objectif

H4 vise à réduire davantage les composants disponibles dans le conteneur
en utilisant une image d'exécution Distroless.

b.  Implémentation

Pour H4, nous avons utilisé une image d'exécution Distroless. Cette base
ne fournit que les composants essentiels à l'exécution et n'inclut
notamment pas de shell traditionnel. Le `Dockerfile` a été adapté pour
utiliser cette base, puis nous avons construit l'image et vérifié que
l'application restait fonctionnelle avant de collecter les mesures de
sécurité.


docker build -t projet:h4 H4/
./tester.sh projet:h4
./collecter.sh projet:h4 H4

c. Résultats obtenus

-   Taille : 83,75 Mo
-   Paquets : 41
-   Vulnérabilités : 253
-   Critical : 2
-   High : 47
-   Medium : 126
-   Low : 76
-   Unknown : 2
-   Digest :
    `sha256:54a68297d63ce364be233a0a8052ecaf12f6f12b764f27ddce58b6647f821737`

d. Analyse des résultats

Le passage à Distroless réduit fortement la taille et le nombre de
paquets. La base retire notamment le shell et plusieurs outils
d'administration, ce qui limite les composants disponibles dans le
conteneur.

H5 :Exécution non-root

a.  Objectif

H5 applique le principe du moindre privilège afin que l'application ne
s'exécute plus avec les privilèges root.

b.  Implémentation

À cette étape, nous avons configuré le conteneur pour exécuter
l'application avec un utilisateur non privilégié plutôt qu'avec `root`.
La directive `USER 65532:65532` a été ajoutée au `Dockerfile`,
conformément au principe du moindre privilège. Après la reconstruction
de l'image, nous avons exécuté les tests fonctionnels et relancé la
collecte automatisée.

dockerfile
USER 65532:65532



docker build -t projet:h5 H5/
./tester.sh projet:h5
./collecter.sh projet:h5 H5


c. Résultats obtenus

-   Taille : 83,75 Mo
-   Paquets : 41
-   Vulnérabilités : 253
-   Critical : 2
-   High : 47
-   Medium : 126
-   Low : 76
-   Unknown : 2
-   Digest :
    `sha256:a3bd63011ec10f141f593219e1f9a7a0f041b2eaf403b5516ea4503f863f0f99`

d. Analyse des résultats

Les mesures de taille, de paquets et de vulnérabilités restent
identiques à H4. Le bénéfice de cette étape concerne surtout les
privilèges d'exécution : l'application fonctionne désormais avec
l'utilisateur `65532:65532` plutôt qu'avec root.

H6 :Système de fichiers en lecture seule

a.  Objectif

H6 vise à empêcher le processus du conteneur de modifier librement son
système de fichiers racine.

b.  Implémentation

Contrairement aux étapes précédentes, H6 est une mesure appliquée au
moment de l'exécution et ne nécessite pas de construire une nouvelle
image. Nous avons réutilisé l'image H5 en ajoutant l'option
`read-only`, qui rend le système de fichiers racine du conteneur
accessible uniquement en lecture. Nous avons ensuite contrôlé la
configuration effective avec `docker inspect`.


c. Résultats obtenus

Le résultat de la vérification est :


ReadonlyRootfs=true


H6 ne possède pas de nouvelle ligne dans evolution.csv, puisqu'aucune
nouvelle image n'est construite.

d. Analyse des résultats

Cette étape ne modifie donc ni la taille, ni le nombre de paquets, ni
les CVE de l'image H5. Elle ajoute plutôt une protection à l'exécution
en rendant le système de fichiers racine du conteneur non modifiable.

H7 :Nettoyage final

a.  Objectif

H7 réalise le nettoyage final de l'image afin d'éliminer les fichiers et
éléments résiduels qui ne sont pas nécessaires à l'exécution.

b.  Implémentation

Pour le nettoyage final, nous avons réduit les fichiers résiduels
conservés dans l'image. L'installation des dépendances est effectuée
sans conserver le cache avec `--no-cache-dir` et sans générer les
fichiers compilés inutiles avec `--no-compile`. Les répertoires
`_pycache` et les fichiers `.pyc` sont également supprimés. Nous
avons ensuite construit l'image finale, vérifié le fonctionnement de
l'application et effectué une dernière collecte.


c. Résultats obtenus

-   Taille : 79,76 Mo
-   Paquets : 41
-   Vulnérabilités : 253
-   Critical : 2
-   High : 47
-   Medium : 126
-   Low : 76
-   Unknown : 2
-   Digest :
    "sha256:c07bad855645e291a3a2f5f42fa520544b5cd55024b8867953a91a250cd59e7a"

d. Analyse des résultats

Le nettoyage final réduit la taille de 83,75 Mo à 79,76 Mo sans modifier
le nombre de paquets ni le nombre de vulnérabilités détectées. H7
constitue ainsi l'image finale durcie utilisée pour la suite des
vérifications de la chaîne d'approvisionnement.

5.  Collecte automatisée

Le script collecter.sh automatise la collecte des mesures après chaque
étape.

Utilisation :


./collecter.sh nom-image etape



Pour chaque image, le script exécute notamment Trivy et collecte :

-   la taille de l'image ;
-   le nombre de paquets ;
-   le nombre total de vulnérabilités ;
-   les vulnérabilités `CRITICAL`, `HIGH`, `MEDIUM`, `LOW` et `UNKNOWN`
    ;
-   le digest / identifiant immuable de l'image ;
-   la version de Trivy ;
-   la date de collecte.

Deux types de résultats sont conservés :

1.  `evolution.csv` contient les mesures synthétiques utilisées pour
    comparer H0 à H7 ;
2.  `resultats/rapport_ETAPE.json` contient le rapport Trivy
    détaillé correspondant à chaque étape.


La version finale du script permet ainsi de conserver à la fois les
données résumées nécessaires aux tableaux et les résultats JSON
détaillés servant de preuve et de source reproductible.

6.  Résultats globaux

Étape Taille Paquets CVE Critical High Medium Low Unknown (Mo)\
H0 723,52 246 4 910 24 305 4 111 470 0

H1 735,95 246 4 724 11 286 3 971 456 0

H2 188,01 95 278 3 84 104 86 1

H3 175,62 95 278 3 84 104 86 1

H4 83,75 41 253 2 47 126 76 2

H5 83,75 41 253 2 47 126 76 2

H7 79,76 41 253 2 47 126 76 2

H6 n'apparaît pas dans ce tableau puisqu'il s'agit d'une configuration
d'exécution et non d'une nouvelle image.

Entre H0 et H7 :

-   la taille passe de 723,52 Mo à 79,76 Mo ;
-   le nombre de paquets passe de 246 à 41 ;
-   les vulnérabilités détectées passent de 4910 à 253.

7.  Tests fonctionnels

Le script 'tester.sh' permet de vérifier automatiquement qu'une image
reste fonctionnelle après chaque étape de durcissement.

Utilisation :


./tester.sh nom-image


Exemple avec l'image finale :

./tester.sh projet:h7

Le script démarre lui-même un conteneur temporaire à partir de l'image
fournie. Le port 18080 de la machine hôte est associé au port
8080du conteneur.

Il attend ensuite que la route :

 
/health

soit disponible, puis vérifie que sa réponse contient :

"status"


Le script vérifie également que la route :

contient :

'fonctionnelle'

À la fin du test, le conteneur temporaire est supprimé automatiquement.
Cette vérification permet de s'assurer que les modifications de sécurité
apportées entre H0 et H7 ne cassent pas le fonctionnement attendu de
l'application.

8.  Génération du SBOM

Le SBOM de l'image finale est généré avec "Syft 1.51.0".

Commande :


syft projet:h7 -o cyclonedx-json > sbom-h7.json


Le fichier produit est :


sbom-h7.json


Résultats observés :

-   taille du SBOM : environ 630 Ko ;
-   paquets : 41 ;
-   exécutables : 357 ;
-   emplacements : 2084.

Le SBOM fournit un inventaire détaillé des composants présents dans
l'image finale.

9.  Signature du SBOM

La signature est réalisée avec Cosign 3.1.3.

Les principaux fichiers locaux utilisés sont :


cosign.key
local-signing-config.json
sbom-h7.json


La commande utilisée pour la signature locale est :

cosign sign-blob \
  --key cosign.key \
  --signing-config local-signing-config.json \
  --bundle sbom-h7.bundle \
  sbom-h7.json

Le fichier produit pour la vérification est :

sbom-h7.bundle


`cosign.key` est une clé privée .


Lors des essais, l'utilisation du journal de transparence Rekor en ligne
a rencontré l'erreur :


http: server gave HTTP response to HTTPS client


Une configuration de signature locale a donc été utilisée pour
poursuivre la démonstration.

10. Vérification de la signature

La vérification du SBOM original doit confirmer que l'artefact n'a pas
été modifié depuis sa signature.

Dans la configuration locale utilisée pendant le projet, la vérification
retourne :

Verified OK

L'option :


insecure-ignore-tlog

a été utilisée lorsque la vérification devait ignorer le journal de
transparence en ligne.

11. Détection d'altération

Afin de démontrer la détection d'une modification, une copie du SBOM
original a été créée.

Fichier original :

sbom-h7.json

Fichier volontairement modifié :

sbom-h7-modifie.json


La signature correspond au contenu original de `sbom-h7.json`.

Lorsque le fichier original est vérifié, le résultat est :


Verified OK


Lorsque `sbom-h7-modifie.json` est soumis à la vérification, Cosign
retourne :


invalid signature


Cette expérience démontre qu'une modification de l'artefact après sa
signature est détectée.

Le fichier `sbom-h7-modifie.json` sert uniquement à cette expérience et
n'est pas destiné à être versionné.

12. Image finale et digest

L'image finale H7 est identifiée par le digest :


sha256:c07bad855645e291a3a2f5f42fa520544b5cd55024b8867953a91a250cd59e7a


Elle a également été publiée sous la référence :


ghcr.io/ange-2372007/mon-projet@sha256:c07bad855645e291a3a2f5f42fa520544b5cd55024b8867953a91a250cd59e7a

L'utilisation du digest est préférable pour les vérifications de chaîne
d'approvisionnement, car il identifie le contenu exact de l'image,
contrairement à un tag mutable.

13. Analyse avec Dockle

L'image finale `projet:h7` a été analysée avec Dockle afin de vérifier
plusieurs bonnes pratiques de sécurité.

Résultat :

-   FATAL : 0
-   WARN : 0

Des éléments informatifs restent signalés, notamment :

-   Docker Content Trust ;
-   absence de `HEALTHCHECK` ;
-   contrôle de détection de mot de passe vide indiqué comme ignoré.

Dockle et Trivy sont complémentaires :

-   Trivy recherche principalement des vulnérabilités connues dans
    les composants ;
-   Dockle contrôle plusieurs bonnes pratiques liées à la
    construction et à la configuration de l'image.

Un résultat Dockle sans FATAL/WARN ne signifie donc pas que l'image ne
possède aucune CVE.

14. Approfondissement Alpine vs Distroless

L'approfondissement choisit consiste à comparer une base Alpine et la
base Distroless utilisée pour H7.

La variante Alpine utilise :


python:3.11-alpine


Construction, test et collecte de la variante de comparaison :


docker build -t projet:alpine Alpine/
./tester.sh projet:alpine
./collecter.sh projet:alpine ALPINE


Le rapport détaillé correspondant est enregistré dans
"resultats/rapport_ALPINE.json".

Résultats

  Critère                    Alpine   Distroless H7
  Taille                  103,04 Mo        79,76 Mo
  Paquets                        65              41
  CVE totales                     9             253
  Critical                        0               2
  High                            2              47
  Medium                          6             126
  Low                             1              76
  Shell           /bin/sh présent     aucun shell

Les deux variantes passent les tests fonctionnels.

Cette comparaison montre qu'une image plus petite et contenant moins de
paquets n'est pas nécessairement celle pour laquelle le scanner détecte
le moins de vulnérabilités.

Distroless produit ici une image plus petite, avec moins de paquets et
sans shell. Alpine présente cependant beaucoup moins de CVE dans le scan
réalisé et conserve un shell, ce qui facilite certaines opérations de
diagnostic.

Le choix dépend donc du compromis recherché entre :

-   taille ;
-   surface fonctionnelle ;
-   vulnérabilités détectées ;
-   facilité de diagnostic ;
-   besoins opérationnels.

15. Reproduction du projet

Une reproduction générale de la chaîne peut suivre l'ordre suivant.

15.1 Construire une image

Exemple avec H7 :


docker build -t projet:h7 H7/


15.2 Démarrer et tester l'application

Utiliser le script en lui passant le nom de l'image :


./tester.sh projet:h7


15.3 Collecter les mesures


./collecter.sh projet:h7 H7


Consulter ensuite :


evolution.csv


15.4 Générer le SBOM


syft projet:h7 -o cyclonedx-json > sbom-h7.json


15.5 Signer le SBOM


cosign sign-blob \
  --key cosign.key \
  --signing-config local-signing-config.json \
  --bundle sbom-h7.bundle \
  sbom-h7.json


15.6 Vérifier l'artefact original

La vérification correcte doit retourner :


Verified OK


15.7 Tester une altération

Créer une copie :


cp sbom-h7.json sbom-h7-modifie.json


Modifier volontairement sbom-h7-modifie.json, puis exécuter la même
procédure de vérification.

Le résultat attendu est :

invalid signature


16. Résumé

La chaîne de durcissement permet de passer de :

H0 : 723,52 Mo / 246 paquets / 4 910 CVE


à :

H7 : 79,76 Mo / 41 paquets / 253 CVE


Le projet montre également que la sécurité d'une image ne se limite pas
au nombre de vulnérabilités détectées. Le durcissement comprend
également :

-   la réduction des composants ;
-   l'exécution non-root ;
-   le système de fichiers en lecture seule ;
-   la suppression des outils inutiles ;
-   la traçabilité des composants avec un SBOM ;
-   la vérification cryptographique des artefacts ;
-   la détection des modifications après signature.

L'ensemble forme une chaîne reproductible permettant de construire,
mesurer, durcir et vérifier une image de conteneur avant son
utilisation.
