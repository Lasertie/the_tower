# Outils, environnement et façon de travailler

Ce fichier décrit **comment** le travail a été fait jusqu'ici, pour qu'une session sans le contexte historique
puisse faire pareil. Il décrit des pratiques observées, pas les consignes internes d'une session (qui varient :
voir la section « Ce qu'une autre session peut ne pas avoir »).

## 1. Le bac à sable (outil bash)
- Répertoire de travail : `/home/claude/` (projet : `/home/claude/the_tower`). Livrables : `/mnt/user-data/outputs/`.
- **Le bac à sable peut être réinitialisé entre deux sessions** : le dossier du projet, le binaire Godot et `/tmp` disparaissent.
  Ce qui survit : `/mnt/user-data/outputs/the_tower.zip` (dernière livraison). **Le zip est la source de vérité.**
- Une commande bash est limitée à ~300 s : toujours préfixer par `timeout N`. Écrire les résultats longs dans un fichier.
- `sh` n'expanse pas `{a,b}` : écrire `mkdir -p a b` (un dossier littéral `{core,scenario,...}` a déjà été créé par erreur une fois).
- Réseau : seuls certains domaines sont joignables (GitHub et `codeload.github.com`, PyPI, npm, archives Ubuntu...).
  OpenGameArt, kenney.nl, poly.pizza ne le sont **pas**. L'API GitHub non authentifiée est vite limitée (utiliser `codeload`).
- Pour partager un fichier avec l'utilisateur : le déposer dans `/mnt/user-data/outputs/` puis appeler l'outil `present_files`.

## 2. Godot 4.3
- Binaire : voir `CLAUDE.md` (téléchargement depuis GitHub). Import : `--headless --import` (après avoir supprimé `.godot/`).
- **Mode headless pur = moteur de rendu factice** : `get_aabb()` des modèles importés renvoie des zéros, donc aucune
  collision de modèle. Les tests doivent tourner sous **Xvfb + Mesa** (`xvfb-run`, `--rendering-driver opengl3`).
  Installer si absent : `apt-get install -y -qq xvfb libgl1-mesa-dri libglx-mesa0 libgl1 libxcursor1 libxinerama1 libxi6 libxrandr2 libxkbcommon0 libfontconfig1 libasound2t64`.
- Bruit inoffensif dans les logs : erreurs ALSA, `Condition "status < 0"` (capture de souris sous Xvfb),
  `Parameter "material" is null` (libération d'une Tour entière), `Parameter "m" is null` (rendu factice).
- `godot -s script.gd` **ne résout pas les autoloads** à la compilation : tester via une *scène* (`res://tests/xxx.tscn`).
- Le moteur de rendu du projet est `gl_compatibility` (fonctionne sous Xvfb et sur machines modestes).

## 3. Tests et captures (c'est ce qui remplace « jouer »)
| Outil | Usage |
|---|---|
| `tests/smoke_test.tscn` | suite d'intégration (106 `OK`). Sortie : lignes `OK`/`FAIL`, `Échecs : N`. Durée : 2 à 3 min. |
| `tests/shot_tower.tscn -- x y z yaw_deg heure out.png [pitch_deg]` | capture de la Tour à une position/heure données |
| `tests/shot_ui.tscn -- <menu\|dialogue\|journal\|journal2\|pause\|conv\|topics\|ascend> out.png` | captures d'interface |
| `tests/shot_life.tscn -- <carry\|strike> out.png` | capture d'une scène de vie (caisse portée, bête frappée) |
| `tests/sim_balance.tscn` (headless) | laisse la société vivre 5 jours sur 8 tirages et imprime l'équilibre |

Pour regarder une capture : l'outil `view` sur le PNG (ex : `/tmp/shot.png`). Toujours regarder après un changement visuel.
Astuce de débogage qui a marché : écrire un **petit banc d'essai isolé** (`tests/dbg_xxx.tscn`) qui reproduit une
situation avec des `print("DBG ...")`, le lancer, puis le supprimer. Ne pas laisser de `DBG` dans la suite.

## 4. Le document partagé (outils « Claude Docs »)
Si la session dispose des outils `mcp__Claude_Docs__*` (batch, guide, update, read, create, export, query, delete) :
- Lire : `read` avec `payload {"projection":"outline"}` (plan avec ids/hashes) ou `{"kind":"view","sinceRev":N}` (blocs changés
  depuis la révision N : **à faire avant toute édition**, car l'utilisateur modifie le document en direct).
- Éditer : `update` avec `payload {"ops":[...]}` ; cibles `{"kind":"find","text":"..."}` ou `{"kind":"blocks","ids":[...]}`.
  Garde-fous : `ifHash` + `ifRev` sur un remplacement de bloc. Une édition `find` ambiguë est refusée (ajouter `"nth":1`).
  `"as":"markdown"` interprète le gras/italique ; `"as":"text"` insère du texte brut (les `**` restent littéraux : bug déjà rencontré).
- Ajouter une section : insérer un bloc `pending` d'abord, puis le remplacer par le contenu.
- Exporter : `export` avec `file` = id de l'onglet, `format: markdown` : renvoie du **base64** (à décoder ; vérifier la taille).
- Lire `guide(["topic.index"])` avant d'éditer ; `topic.editing` pour les ops délicates, `topic.comments` pour les commentaires.
- Après la création/mise à jour, l'outil `Artifact` avec `action:"open"` affiche le document à l'utilisateur.
- L'utilisateur édite aussi le document : toujours relire avant de s'appuyer sur sa mémoire, ne jamais écraser ses modifications.

## 5. Recherche web / ressources
- `web_search` pour trouver des ressources libres ; **télécharger uniquement via bash** depuis GitHub (`codeload.github.com/<org>/<repo>/zip/refs/heads/main`).
- Licences : toujours vérifier et copier le texte de licence dans `assets/licenses/` + `CREDITS.md`. Les dépôts « Starter Kit » de
  Kenney sont MIT (code) avec modèles CC0 ; les packs de mobilier viennent du dépôt `yuyou-dev/OpenHome3D` (CC0, licences d'origine incluses).

## 5 bis. Cadence de travail qui a bien fonctionné
1. Lire l'état (zip, docs). 2. Concevoir avec l'utilisateur (document partagé) pour tout ce qui est structurant.
3. Implémenter par **petites tranches verticales** (code + test + capture). 4. Corriger les vrais bugs trouvés par les tests
(plusieurs bugs d'architecture ont été trouvés ainsi : voir `docs/HANDOFF.md`, « Leçons »). 5. Mettre à jour les docs.
6. Zipper, présenter, résumer : ce qui est fait, ce qui est testé, ce qui ne l'est pas, ce qui reste à trancher.

## 6. Ce qu'une autre session peut ne pas avoir (et que faire alors)
| Peut manquer | Alternative |
|---|---|
| Accès au bac à sable / bash | impossible de tester : écrire le code, le dire clairement, ne rien affirmer comme testé |
| Outils « Claude Docs » / `Artifact` | éditer `docs/DESIGN_BIBLE.md` dans le dépôt ; signaler qu'il faudra resynchroniser le document partagé |
| Réseau GitHub | utiliser les modèles déjà présents dans `assets/` ; ne pas en ajouter |
| `present_files` | donner le chemin du zip |
| Mémoire / historique de conversation | tout est dans `docs/` : `DEV_LOG.md` donne le « pourquoi » des décisions |
| Rendu graphique (Xvfb) | impossible de vérifier visuellement : limiter les changements visuels et le dire |
| Même format de réponse (mobile, longueur) | s'adapter aux consignes de la session ; garder le français |
Ne jamais supposer qu'un outil existe : vérifier la liste d'outils de la session avant de planifier.
