# Feuille de route détaillée : Tranche A (étage 1 refondu de bout en bout)

Objectif : **valider toute la méthode** sur l'étage 1 : sortie par Sceau à verrous, aucun guidage, espaces imposants, savoir qui se mérite,
statistiques par les actes. Chaque étape = code + test(s) + capture si visuel + mise à jour des docs. Ordre recommandé : A1 → A2 → A3 → A4 → A5 → A6 → A7 → A8.

## A0 : Géographie close  ✅ FAIT
Faux ciel, montagnes, Bout du monde, Fiole de la cascade (objet `waterfall_vial`, sans usage encore), trappe + Chambre du Sceau sur l'Axe,
animation d'ascension, arrivée dans la cabine de l'Asile. Tests : « Chambre du Sceau », « Superposition sur l'Axe », « ascension ».

## A1 : Sceau et verrous ✅ FAIT
**But** : la sortie d'un étage = un `Seal` à 2–4 `Lock` de types différents, plusieurs `routes` ; aucune route à élément unique.
- Nouveaux fichiers : `scripts/seal/lock.gd` **(à créer)** (`Resource` : `id`, `type` ∈ {CONSENT, MERIT, MOMENT, WATCH, STATE, OFFERING}, `params: Dictionary`, `glyph: StringName`),
  `scripts/seal/seal.gd` **(à créer)** (`Resource` : `locks`, `routes: Array[Array[StringName]]`, `evaluate(ctx) -> {open, satisfied: {lock_id: bool}, route}`),
  `scripts/seal/seal_context.gd` **(à créer)** (construit le contexte : confiance via `Society`, objets/flags, `GameClock`, `LawSystem.watchers_near`, folie du joueur).
- Types à implémenter pour l'étage 1 : CONSENT (`Society.person(&"elder").trust >= 40` ET aucune rancune < −15 chez enfant/fermière/chasseur/garde),
  MERIT (flag/objet « bannière » OU 5 cornes... : preuve d'une épreuve lourde), WATCH (`max_watchers = 0` autour de la Chambre **et** Ancien absent),
  STATE/OFFERING prévus (étage 2).
- Routes étage 1 : **Honneur** = CONSENT + MERIT (l'Ancien descend avec le héros : voir A3) ; **Ruse** = laissez-passer + WATCH (Marque `Intrus`).
- Brancher : `Floor01Village.seal` ; `VillageLayout._on_seal` appelle `seal.evaluate` au lieu de `floor_ctrl.attempt_exit` ; le Sceau reste **inerte** sinon.
- **Retour visuel (sobre)** : un glyphe par verrou sur les piliers de la Chambre (déjà 6 piliers) qui s'allume quand le verrou est satisfait ; niveau d'aide
  réglable (0 aucun, 1 glyphes, 2 résonance avec relique). Un seul shader/matériau émissif par pilier ; ne pas surcharger.
- Marques : `WorldFlags` `mark_reconnu` / `mark_intrus` posées selon la route.
- **Tests** : sceau inerte sans verrous ; chaque verrou s'allume isolément ; route Honneur ouvre ; route Ruse ouvre ; **aucun verrou seul n'ouvre** ;
  glyphes reflètent l'état ; marque posée. Supprimer l'usage de `ScenarioManager` pour la sortie (garder le suivi interne si utile).

## A2 : Journal sans guidage
- Retirer de `Hud._refresh_journal` la section scénarios (`Étage N - titre`, pistes, compteurs `(x/y)`, « Épreuve résolue »).
- Retirer les toasts `condition_discovered`, `scenario_resolved` (`Hud.setup`), le message `VillageLayout._on_floor_cleared` (ou le rendre purement diégétique).
- Garder/étendre : Observations (phénomènes notés), Témoignages (qui a dit quoi, fiabilité), Rumeurs, Habitants rencontrés, Marques, **Stats** (A7).
- Ajouter le **Carnet** (optionnel) : notes libres + épingler un témoignage/observation.
- `Cast.FACTS[...]["discovers"]` ne doit plus « révéler une condition » : un fait appris devient un **témoignage** du journal (texte), pas un objectif.
- **Test statique** : le journal ne contient aucun mot d'une liste d'objectifs (« Résoudre », « Objectif », compteurs `/`).

## A3 : Requêtes et rites dans la société
- API : `Society.request(pid, kind, params) -> {accepted, reason}` ; acceptation selon confiance, humeur, relations, intérêts ; l'habitant **planifie** réellement.
- Rite de l'Ancien : sur requête (confiance ≥ 40 + consentement), il se rend à la trappe à l'heure convenue et descend avec le héros (corps : `Inhabitant`
  doit pouvoir *suivre/mener* : nouvelle tâche `lead` ; `Tower.travel` pour l'accompagnement).
- UI : entrée « Demander un service... » dans la conversation (`Hud._conv_menu`).
- **Tests** : acceptation/refus selon confiance ; l'Ancien est bien à la trappe à l'heure ; le Sceau, ouvert par lui, satisfait CONSENT.
- Réciprocité (les habitants demandent des services) : en seconde passe.

## A4 : Le Dédale (labyrinthe imposant, inspiré du bible §8)
- `scripts/world/maze.gd` **(à créer)** (génération **seedée**, déterministe) : grille 41 × 41 cellules de 4 m, arbre couvrant + ~15 % de boucles + 3 clairières + cercle intérieur ;
  sortie : `walls` (liste de segments), `landmarks`, `center`. Rendu : `MultiMeshInstance3D` pour les haies (7 m), collisions par segments fusionnés.
- Orientation sans carte : ombres/soleil (déjà un cycle jour/nuit), cloche du village (volume selon la distance), **craie** (item de la ferme : marques posées par le joueur,
  sauvegardées), **serpe** (coupe 10 % de haies « fragiles » ; repoussent en un jour : état dans `Society.resources`/`consumed`).
- Habitants : l'**Ermite** (nouvelle `Person` étage 1, vit dans le Dédale, savoir + secret), 2–3 égarés (dont le fils du forgeron), **Bête des Haies** (variante d'`Enemy`, plus dangereuse la nuit).
- Bannière au centre = trophée MERIT (A1).
- Emplacement : nord-ouest, hors de la zone actuelle des haies-prototype (les remplacer). Budget : 300–500 instances max par MultiMesh.
- **Tests** : labyrinthe résoluble (BFS entrée→centre), déterministe (même graine = même murs), haies fragiles repoussent, craie sauvegardée, performance (compter les nœuds).

## A5 : Le Puits à marée
- Niveau d'eau = fonction de `GameClock` (cycle 6 h) ; la relique n'est accessible qu'à marée basse ; petit donjon vertical sous le puits (2–3 salles).
- L'Enfant connaît un passage secret (faille) : il peut prendre la relique avant le joueur (déjà simulé via `WORK_EFFECTS`) ; la révélation du passage est un fait de `Cast`.
- **Tests** : accès selon l'heure ; le passage de l'Enfant ne dépend pas de la marée.

## A6 : Lanterne d'écho (la relique) : **usage à valider avec l'utilisateur** (décision 2)
- Proposition : rejouer le passé récent d'un lieu. Technique : `Society` garde un **journal d'échantillons** par lieu (position/activité des personnes toutes les 10 min sur 24 h) ;
  la lanterne instancie des silhouettes translucides (`Inhabitant` en mode fantôme, sans collision) qui rejouent. Charge limitée, recharge au Puits.
- Dilemme : l'utiliser, l'offrir à l'Ancien (+40 confiance), la rendre à l'Enfant (révèle son passage). Si l'utilisateur choisit une autre option (navigation du Dédale, arme), adapter.

## A7 : Statistiques par les actes (bible §13), système piloté par des données
- Autoloads : `PracticeBus` (`emit_practice(tag, amount, ctx)`), `StatsSystem` (état, paliers, sauvegarde). Ressources : `StatDef` (`id`, `name`, `practices: {tag: poids}`,
  `thresholds`, `hidden`, `unlock: {practice: tag, count: n, ...}`, `effects`).
- Points d'émission : déplacement (courir/grimper/chute), combat (esquive, coups), social (convaincre, mentir réussi), exploration (nuit dans le Dédale, folie tenue),
  Sceau (verrous satisfaits). Rendements décroissants, plafonds par arc.
- Départ visibles : Vigueur, Agilité, Acuité, Sang-froid. Cachées (déblocage par action cachée) : Orientation, Duplicité, Pas silencieux, Endurance à la folie, Lecture des Glyphes.
- Journal : décrire en mots, pas en nombres. Une stat débloquée n'apparaît qu'alors.
- **Tests** : pratique → progression ; déblocage caché ; rendements décroissants ; sauvegarde ; une pratique inconnue ne casse rien.

## A8 : Invariants automatiques (garde-fous du bible §5)
- Solveur de Sceau : exploration d'états abstraits (objets, confiance, flags, heure) prouvant qu'**au moins une route est atteignable** depuis tout état de partie réaliste.
- « Rien n'est perdu » : pour chaque ressource clé, un chemin alternatif existe (relique prise par l'Enfant ⟹ obtenable par confiance).
- « Double source » : chaque information essentielle a ≥ 2 détenteurs/sources indépendants.
- « Aucun verrou à élément unique » : assertion sur les `Seal` définis.
- « Journal sans objectif » : voir A2.

## Après la tranche A
Tranche B (Asile-labyrinthe, **prototype non euclidien d'abord**), C (Canopée), D (Champ de bataille), E (Archipel + boss). Voir bible §17.
Mettre à jour `docs/HANDOFF.md` §3 à chaque étape terminée.
