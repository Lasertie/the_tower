# Journal de développement : décisions, pivots et raisons

Chronologique. Chaque entrée : ce qui a été décidé, **pourquoi**, ce qu'on a appris. (Les numéros de section renvoient à `docs/DESIGN_BIBLE.md`.)

## 0. Cahier des charges initial (utilisateur)
Action-RPG solo, Tour de 5 étages narratifs (Village, Asile, Canopée, Champ de bataille Murim/Géants, Archipel), scénarios à conditions de victoire
alternatives, flags persistants, lois de la Tour avec failles cachées, un seul héros. Le texte parlait de `struct`/`Resource` à la Bevy : traduit en
idiomes Godot (autoloads, `Resource`, signaux). **GDScript** et non PHP (PHP n'existe pas dans Godot) : l'utilisateur aime l'open source et PHP, Godot est libre.

## 1. Fondations (code de base)
`WorldFlags`, `Scenario`/`WinCondition`/`ScenarioManager`, `FloorLaw`/`LawExploit`, `SaveSystem`, `FloorController`, première version de l'Asile.
Raison : couvrir les 5 livrables du cahier des charges (scénarios, flags, lois/exploits, contrôleurs d'étage, sauvegarde).
Leçon : `godot -s` ne résout pas les autoloads : on teste via des scènes.

## 2. Phase 1 (Village) et Phase 2 (Asile)
Joueur, ennemi, horloge, zones déclencheurs ; folie, hallucinations, 4 chemins de victoire, objets « consommés » sauvegardés.
Choix : décor procédural (boîtes) pour avancer vite et tester ; la validation se fait par tests headless puis sous rendu logiciel.

## 3. Refonte « monde unique » (demande : retirer les triches, empiler les étages, vrais modèles, UI)
- **Étages empilés** dans un seul monde (même horloge, mêmes lois) au lieu de scènes qui se remplacent. Raison : l'utilisateur veut « un monde entier régi par les mêmes lois ».
- **LawSystem** : une loi s'applique à *tous* les corps de l'étage (le monstre retourne au plafond comme le joueur). Failles = exemptions *personnelles*.
- **Plus de touches de debug** ; la mort fait payer (2 h, chaos +1) au lieu d'une téléportation gratuite.
- **Pistes et journal** à la place d'une checklist visible (contrainte « Scénarios, pas Checklists »).
- **Vrais modèles CC0** (Kenney, KayKit) via GitHub ; Xvfb+Mesa installés pour **voir** le rendu (captures) : décisif pour trouver l'orientation des modèles (+Z) et l'échelle.
- Bug majeur trouvé : désactiver un étage désactivait ses collisions ⟹ chute à travers le sol (cf. HANDOFF §6).

## 4. Habitants autonomes puis « lois » vs « phénomènes »
Premier jet : emplois du temps liés à l'horloge (le garde dort avant l'aube, déjeune à midi). Retour utilisateur : **les habitants ignorent les lois** (sauf étages à
thème). Conséquence : plus aucun dialogue qui énonce une règle ; côté joueur on parle de « phénomènes » ; la **faille de l'aube devient émergente** (« porte sans
surveillance » : le sceau ne retient rien quand personne ne regarde), au lieu d'une plage horaire codée.

## 5. La société simulée (retour : « un monde qui vit en lui-même »)
Constat : un PNJ n'est vivant que s'il a des intérêts, des relations et une influence **sans le joueur**. Décision d'architecture : la vie est des **données**
(`Person`, `Society`) simulées sur tous les étages ; les corps 3D deviennent des **marionnettes**. Ajouts : décisions par utilité, relations/ragots/réputation,
savoir par confiance (secrets à seuils propres à chaque détenteur), ressources du monde consommées/renouvelées par les habitants (Fosse, caisses, relique, parchemin,
patients), conversation à choix. Simulation de 5 jours × 8 tirages pour régler l'équilibre : un désir qui rendait le Chasseur « oisif » annulait son influence ⟹ corrigé.
Raison du choix « ressources + reflet » : permet de simuler hors champ pour tous les étages sans coût, et d'animer seulement ce qui est à l'écran.

## 6. La vie se voit
Tâches visibles (frapper, porter une caisse sur la tête, ramasser, soigner), conversations face à face, ragots audibles de près qui nourrissent le journal.
Bugs réels : réservation de cible levée trop tôt (double retrait), courage du Chasseur sous le seuil de fuite, tests instables (aléas) ⟹ tests déterministes.

## 7. Bible de conception v1 (planification avec l'utilisateur)
Idée unificatrice : **la Clause** (la Tour est un registre ; lois de régime et sceaux de sortie sont des clauses ; les habitants vivent sous des clauses qu'ils ne lisent pas ;
étages thématiques : lettre sans esprit). **Sceau à verrous** (6 types), routes, facilitateurs, Marques, Glyphes, retour diégétique, garde-fous testés. Étages 1 à 5 détaillés.
Document partagé édité en direct par l'utilisateur (voir `docs/WORKFLOW_TOOLS.md` §4).

## 8. Décisions de l'utilisateur sur la bible
Monde clos sous faux ciel (il adore le ciel), **pas d'escalier visible** ⟹ ascension cachée (animation) ; bords : montagnes ou **Bout du monde** (eau qui tombe, avec un objet
utile à l'étage 5) ; relique : garder le dilemme mais changer l'usage ; étages plus vastes (graphismes = preuve de concept) ; Asile non euclidien « si on arrive à des effets
poussés » ; route du Culte gardée (en attente propre) ; porte des Oubliés **cachée et révélée par un objet** ; stats formées par les actes avec déblocages cachés ; retours visuels
soignés mais sobres ; tranche A d'abord ; **escaliers toujours superposés (l'Axe)** ; **100 étages** (arcs de dix, trois niveaux de fabrication, Refuges).

## 9. A0 : géographie close (implémenté)
Suppression de la rampe, des trous de dalle, de la porte et des murs ; montagnes + Bout du monde (cascade, brume) ; Fiole de la cascade ; trappe → Chambre du Sceau sous la maison
de l'Ancien (sur l'Axe) ; animation d'ascension (shader de traînées dorées, secousse) ; cabine d'arrivée de l'Asile sur l'Axe ; `Tower.travel`. 106 tests.
Constats : la cascade n'est visible que de près (rebord + brume pour l'horizon) ; un test plaçait un habitant dans la fontaine (corps coincé sous le sol) ; la Chambre doit avoir son propre éclairage
(sous terre : pas de soleil).

## 10. Incident d'environnement
Le bac à sable a été réinitialisé en cours de travail (dossier projet et Godot perdus). Le zip livré a permis de tout restaurer. Leçon : **le zip est la source de vérité** et la documentation de reprise
(`CLAUDE.md`, `docs/`) a été écrite pour qu'une session sans contexte puisse continuer.

## 13. A1 — Sceau et verrous
Nouveau sous-système `scripts/seal/` : `Lock` (Resource, enum Type), `Seal` (routes = tableaux d'ids de verrous), `SealContext` (snapshot joueur/société/lois au moment du contact).
Étage 1 : 4 verrous (CONSENT trust Ancien ≥ 40, MERIT pit_kills ≥ 5, WATCH 0 observateur à la trappe, ITEM elder_pass), 2 routes (Honneur = CONSENT+MERIT, Ruse = WATCH+ITEM).
`VillageLayout` : 4 piliers indépendants (un par verrou, s'allument en vert quand satisfait), 2 piliers décoratifs ; `_on_seal` appelle `Floor01Village.attempt_seal` ; surveillance vérifiée à la trappe (surface) et non dans la chambre souterraine.
`Floor01Village` : `attempt_seal()` remplace `attempt_exit()` ; `on_pit_kill()` remplace l'appel direct à `ScenarioManager` ; `is_cleared()` lit les flags `FLAG_HONOUR` / `FLAG_RUSE` ou l'ancien scénario (rétrocompatibilité).
Tests : 11 nouveaux checks A1 → 117 OK / 0 échec.
Leçon : vérifier la surveillance à la trappe en surface (et non au sceau souterrain à -8m) ; `guard.catch_up` suivi de 3 frames est trop fragile pour un test de position, préférer un placement manuel + état forcé.

## 11. Prochaines décisions attendues de l'utilisateur
Voir `docs/HANDOFF.md` §4 (ouvertes) : usage de la relique, coût des Oubliés, objet qui révèle la Porte, stats de départ, verrou « Moment », seuil de folie, étages 6 à 10.

## 12. Migration étages en scènes (.tscn)
Demande : pouvoir assembler les 100 étages dans l'éditeur Godot plutôt que tout construire en code.
Décision : chaque étage devient une scène héritée (`FloorLayout.tscn` → `village.tscn`, `asylum.tscn`) instanciée dans `tower.tscn`.
Changement principal : `FloorLayout._ready()` vidé ; la construction réelle déplacée dans `FloorLayout.setup()` appelée explicitement par `Tower._setup_floors()`.
Raison : les enfants en scène `.tscn` ont leur `_ready()` déclenché *avant* le parent — `floor_number`, `base_y`, `player` et `layout_state` n'étaient donc pas encore assignés.
Pour ajouter l'étage 3 : créer `floor3.tscn` héritant de `FloorLayout.tscn`, lui attacher le script du nouvel étage, le glisser dans `tower.tscn` dans l'éditeur. `tower.gd` lit automatiquement tous les enfants `FloorLayout` dans l'ordre.
Tests : 106 OK / 0 échec (Godot 4.3). Note : Godot 4.7 a 3 régressions indépendantes (UI HUD + timing ascension) non liées à ce changement.
