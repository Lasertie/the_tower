# Passation : état du projet et reprise

Dernière mise à jour : A1 — Sceau et verrous. Tests : **117 OK / 0 échec** (Godot 4.3).

## 1. Reprendre en 10 minutes
1. Lire `CLAUDE.md` (règles, commandes), puis ce fichier, puis `docs/ARCHITECTURE.md`.
2. Restaurer l'environnement (commandes dans `CLAUDE.md`) : zip → Godot 4.3 → import → tests. Si `Échecs : 0`, vous êtes au bon point. **Godot 4.7 a 3 régressions d'interface non liées au code du jeu** : utiliser 4.3 pour les tests.
3. Regarder le jeu : `tests/shot_tower.tscn -- -9.5 0.3 -10 0 12 /tmp/a.png` (village), `-- -14 -7.7 -12 0 12 /tmp/b.png -8` (Chambre du Sceau),
   `-- 0 0.3 113 180 12 /tmp/c.png -28` (Bout du monde). Voir `docs/WORKFLOW_TOOLS.md`.
4. Ouvrir le document de conception vivant (lien dans `CLAUDE.md`) : sections 5 (Sceau), 8 (étage 1), 13 (stats), 14 (100 étages), 18 (décisions).
5. Continuer par `docs/ROADMAP_TRANCHE_A.md` : prochaine étape = **A1 (Sceau et verrous)**.

## 2. Ce qui fonctionne (et est testé)
- **Monde empilé** : étage 1 (Village, 14 m) sous l'étage 2 (Asile, 3,6 m) ; une seule horloge, mêmes lois ; étage actif déduit de l'altitude.
- **Géographie close** (étage 1) : faux ciel qui suit l'horloge ; montagnes N/O/E ; Bout du monde au sud (cascade + brume + Fiole de la cascade) ;
  aucune muraille ni escalier visible ; **Chambre du Sceau** sous la maison de l'Ancien (trappe → fondu → chambre) ; le Sceau s'éveille quand
  l'épreuve est résolue ; franchissement = **animation d'ascension** (voile doré, secousse) → arrivée dans la cabine de l'Asile **exactement sur l'Axe**.
- **Lois communes** : gravité inversée à minuit (étage 2) subie par le joueur, les monstres **et** les habitants ; faille personnelle (bottes d'ancrage).
- **Sceau actuel (provisoire)** : s'ouvre si le scénario est résolu (un des 4 chemins) ou par une faille (laissez-passer de l'Ancien, ou **porte
  sans surveillance** : le Garde dort/déjeune/fuit). Marque le jeu comme « phénomène observé ».
- **Société simulée** (6 personnes, 2 étages) : habitudes, besoins, désirs, peur, solitude, caprices, rencontres, querelles, amitiés, **ragots** qui
  circulent et fixent une **réputation** du joueur ; savoir par **confiance** (secrets à seuils propres à chaque détenteur) ; vie **hors champ**.
- **Influence sur la Tour** : le Chasseur abat les bêtes de la Fosse (renouvelées), la Fermière rentre ses caisses, l'Enfant peut prendre la relique avant
  le joueur (et la rendre contre confiance), l'Ancien retrouve son parchemin, l'Infirmière soigne des patients. Visible quand on est là (strike/carry/grab/tend).
- **Interface** : menu, HUD, dialogues à choix, journal (confidences, rumeurs, habitants, phénomènes), pause/sauvegarde/chargement, voile d'ascension.
- **Sauvegarde** complète (joueur, étages, société, flags, scénarios, horloge, lois), aller-retour testé.

## 3. Ce qui n'est PAS fait (liste honnête)
- Étages 3 à 5 (et 6 à 100) : rien. L'ascension depuis l'étage 2 affiche « pas encore bâti ».
- Système **Sceau/verrous** (aujourd'hui : scénario résolu OU faille) ; glyphes ; niveaux d'aide.
- **Journal sans guidage** : le HUD affiche encore les pistes du scénario et un toast « Épreuve résolue » (dette, voir §5).
- Labyrinthe de haies imposant (aujourd'hui : deux anneaux d'arbres), Ermite, Bête des Haies, craie, serpe, Puits à marée, Lanterne d'écho.
- Asile-labyrinthe géant et non euclidien ; Porte des Oubliés cachée et révélée par un objet (aujourd'hui : 100 % de folie) ; route du Culte.
- **Statistiques du héros** ; requêtes/rites dans la société ; factions (étage 3+).
- Son, musique, manette, réglages, localisation. Rien n'a été **joué à la main** : tout est validé par tests et captures. Performance sur GPU réel : non mesurée.

## 4. Décisions de conception (tranchées / ouvertes) : miroir de la section 18 du bible
Tranchées : retours visuels de Sceau (glyphes, soignés mais sobres) ; étages agrandis ; Asile non euclidien (prototype d'abord) ; Porte des Oubliés
cachée, révélée par un objet, jamais d'entrée automatique ; route du Culte conservée (en attente propre par interrupteur) ; tranche A d'abord ;
stats formées par les actes avec déblocages cachés ; l'Axe (ascensions superposées) ; 100 étages en arcs de dix ; étages restent empilés.
Ouvertes : usage exact de la relique (Lanterne d'écho proposée) ; coût de la traversée des Oubliés (relation effacée / Marque perdue / zone inconnue) ;
objet qui révèle la Porte des Oubliés ; liste de départ des stats ; verrou « Moment » de l'étage 1 (retiré par l'utilisateur) ; seuil/sanction de la folie
à 100 % (échec de partie proposé par l'utilisateur) ; contenu des étages 6 à 10.

## 5. Dette technique et code mort
- `FloorController`/`Scenario`/`WinCondition` + HUD : checklist visible et toasts d'objectifs : **à supprimer en A2** (invariant n°2).
- `Floor03Canopy` (stub), `Door` (inutilisé) : à supprimer ou réutiliser.
- `Floor02Asylum.try_forgotten_door` : exige 100 % de folie ; contredit la décision (porte cachée + objet). À refaire en tranche B.
- Le village est vide au-delà de ±50 m (l'espace attend le futur Dédale) ; les arbres sont non solides.
- `VillageLayout` mêle décor, ressources et logique : prévoir de le découper quand le Dédale arrive.
- `tests/smoke_test.gd` est un fichier unique de ~600 lignes : le scinder par domaines quand il grossit.

## 6. Leçons (bugs réels rencontrés, pour ne pas les refaire)
| Symptôme | Cause | Remède |
|---|---|---|
| Le joueur traverse le sol à l'étage 2 | `process_mode = DISABLED` sur un layout désactive aussi ses collisions (la dalle d'un étage = sol du suivant) | `FloorLayout.set_active()` ne gèle que enemis/contrôleur/habitants |
| Modèles sans collision en test | rendu headless factice : `get_aabb()` = 0 | tests sous Xvfb + `--rendering-driver opengl3` |
| `godot -s` : « Identifier not found: GameClock » | autoloads non résolus à la compilation en mode `-s` | tester via une scène `.tscn` |
| Parse error « type inferred from a Variant » | avertissement traité en erreur | typer explicitement (`var x: Dictionary = ...`) |
| Le Chasseur ne chassait pas | un désir à la Fosse remplaçait l'activité « work » par « idle » : aucun effet sur le monde | un désir vers le même lieu garde l'activité d'habitude |
| Un patient de trop disparaissait | réservation levée avant la fin de la tâche : le décor retirait la cible une 2ème fois | `task_finished(kind, done)` : on ne libère qu'en cas d'échec |
| Le Chasseur fuyait les bêtes qu'il chasse | courage 0,7 < seuil 0,8 | courage 0,85 |
| Un test échoue « au hasard » | la société avance en temps réel (aléas) | `Society.set_process(false)`, `rng.seed`, `set_block_signals(true)` autour des boucles d'effets |
| Un corps se retrouve sous le sol | placé **dans** un volume solide (fontaine) par un test | placer en terrain dégagé |
| Le joueur reste bloqué à l'entrée d'un passage | un habitant solide s'y est arrêté | dégager avant le test ; en jeu c'est transitoire |
| Astérisques littéraux dans le document | `"as":"text"` ne parse pas le markdown | `"as":"markdown"` pour la mise en forme |
| Le modèle du personnage regarde en arrière | les modèles Kenney regardent vers +Z, le jeu vers −Z | `model.rotation.y = PI` |
| Une zone d'interaction n'a pas de forme | `Interactable` ne crée sa forme que s'il n'a pas d'enfant à `_ready` | ajouter le modèle **après** `add_child` |
| Ancien code qui réapparaît chez l'utilisateur | dézippage par-dessus un ancien projet (fichiers supprimés non supprimés) | conseiller un dossier vide ; supprimer `.godot/` |
| Perte du dossier de travail | bac à sable réinitialisé | le zip de `/mnt/user-data/outputs` fait foi ; documentation dans `docs/` |

## 7. Pour la prochaine livraison
Mettre à jour : `docs/HANDOFF.md` (état, tests), `docs/DEV_LOG.md` (une entrée), `docs/ARCHITECTURE.md` si l'API change, `CREDITS.md` si nouveaux assets ;
puis zipper sans `.godot/`, copier vers `/mnt/user-data/outputs/the_tower.zip`, `present_files`, et résumer en français (fait / testé / non testé / à trancher).
