# The Tower (titre provisoire)

> **Reprise de projet / nouvelle session ?** Lire d'abord `CLAUDE.md`, puis `docs/HANDOFF.md`, `docs/ARCHITECTURE.md`,
> `docs/ROADMAP_TRANCHE_A.md`, `docs/DESIGN_BIBLE.md`, `docs/WORKFLOW_TOOLS.md`, `docs/DEV_LOG.md`.

Action-RPG solo en 3ème personne (Godot 4.3, GDScript). Un seul héros gravit une Tour dont les étages sont
**empilés pour de vrai** dans un seul monde, régi par les mêmes lois.

## Lancer
Ouvrir le dossier dans Godot 4.3+ puis F5. Menu : Nouvelle partie / Continuer / Quitter.

## Contrôles
ZQSD / WASD / flèches : bouger · Espace : sauter · Clic gauche : attaquer · E : interagir / parler ·
Tab ou J : journal · Échap : pause (sauvegarde / chargement).

## Principes de conception
- **Un seul monde.** Village (étage 1) et Asile (étage 2) sont superposés ; on passe de l'un à l'autre par
  un vrai escalier, traversant une dalle trouée. Une seule horloge, une seule mémoire (`WorldFlags`).
- **Les mêmes lois pour tous.** `LawSystem` applique les lois de chaque étage à *tous* les corps qui s'y
  trouvent : à minuit à l'Asile, la gravité s'inverse pour le joueur comme pour les monstres. Seule une
  faille personnelle (objet, heure, état) en exempte.
- **Sorties scellées par une loi.** La porte de chaque escalier ne s'ouvre que si l'épreuve est résolue,
  ou si le joueur trouve une faille (l'aube à l'étage 1, le laissez-passer de l'Ancien).
- **Scénarios, pas checklists.** Aucune liste d'objectifs affichée : le journal ne contient que ce que le
  joueur a *appris* (dialogues, observation). Les failles cachées n'y apparaissent qu'une fois employées.
- **Une société qui vit sans le joueur.** `Society` simule en permanence, sur TOUS les étages, des
  personnes (`scripts/society/`) : tempérament, besoins (fatigue, compagnie), désirs, relations, savoir.
  Toutes les 10 minutes de jeu, chacune décide de son activité (habitudes, fatigue, peur, désirs, solitude,
  caprice), agit sur la Tour, croise d'autres personnes (amitiés, querelles, ragots). Les corps 3D
  (`Inhabitant`) ne sont que les marionnettes de ces personnes sur l'étage actif ; ailleurs, elles vivent sans
  corps, et la mort du joueur fait passer 2 h de vraie vie à la société.
- **Les habitants influent sur la Tour.** Le Chasseur abat réellement les bêtes de la Fosse (que la Tour
  repeuple), la Fermière rentre ses caisses, l'Enfant peut s'emparer de la relique du Puits avant vous, l'Ancien
  peut retrouver son parchemin, l'Infirmière soigne des patients. Le décor n'est que le reflet de ces
  ressources ; le joueur coopère ou entre en concurrence.
- **La vie se voit.** Quand un habitant agit sur la Tour et que l'étage est actif, on le voit faire : le Chasseur
  marche jusqu'à une bête et la frappe, la Fermière porte une caisse sur la tête jusqu'à la grange, l'Enfant et
  l'Ancien vont ramasser leurs trouvailles, l'Infirmière se rend au chevet d'un patient. Deux voisins qui se
  rencontrent se font face et échangent des répliques ; si le joueur est assez près, il surprend leurs ragots
  (ils rejoignent le journal). Hors de vue, le même effet s'applique d'un coup, sans animation.
- **Le savoir se mérite.** Chaque secret a un seuil de confiance propre à chaque détenteur (le Garde est
  honteux de sa sieste ; le Chasseur la connaît et la lâche plus facilement ; l'Ancien sait pour les sceaux
  mais ne parle qu'à une confiance très élevée). « Bavarder » ne divulgue jamais un secret. Les actes du
  joueur circulent par ouï-dire, pondérés par les relations entre habitants (réputation).
- **Ils ignorent les lois de la Tour** : ils ne connaissent que des faits, des rumeurs, des souvenirs. Ils les
  subissent seulement comme des corps (gravité inversée comprise).
- **Des failles émergentes.** Le sceau de l'étage 1 ne retient rien quand personne ne surveille la porte :
  il suffit que le garde dorme (avant l'aube), déjeune ou fuie un monstre. Rien ne l'explique au joueur.
- **Pas de triche développeur.** Plus de touches de debug. La mort fait payer : 2 h passent, le chaos monte.
- **Conséquences persistantes.** Les flags (Gourou tué, patients soignés, Porte des Oubliés) survivent
  aux sauvegardes et se lisent dans le journal (« La Tour se souvient »).

## Tests
Les tests utilisent de vrais collisions issues des modèles 3D, donc un rendu (même logiciel) est requis :

    xvfb-run -a godot --rendering-driver opengl3 --path . res://tests/smoke_test.tscn

`tests/sim_balance.tscn` (headless) laisse la société vivre plusieurs jours sur plusieurs tirages pour régler l'équilibre.

`tests/shot_tower.tscn`, `tests/shot_ui.tscn` et `tests/shot_life.tscn` produisent des captures d'écran pour vérifier le rendu.

Voir `CREDITS.md` pour les licences des modèles et de la police.

## Documentation de reprise
- `CLAUDE.md` : instructions de projet, invariants de conception, commandes.
- `docs/HANDOFF.md` : état, ce qui reste, dette, leçons (bugs réels).
- `docs/ARCHITECTURE.md` : modules, flux, API, recettes d'extension.
- `docs/ROADMAP_TRANCHE_A.md` : prochaines étapes au niveau fichier/test.
- `docs/DESIGN_BIBLE.md` : la vision (instantané du document partagé).
- `docs/WORKFLOW_TOOLS.md` : sandbox, Godot, captures, outils, ce qui peut manquer à une session.
- `docs/DEV_LOG.md` : historique des décisions et pivots.
