# Architecture technique

Godot 4.3, GDScript typé. Unités : mètres. Tout le contenu est **procédural** (volumes simples + modèles CC0) : pas de scène
`.tscn` de niveau, seulement `menu.tscn` et `tower.tscn` (qui ne contient que le script `Tower`).

## 1. Vue d'ensemble

```
menu.tscn ──(Nouvelle partie / Continuer)──▶ tower.tscn  (script Tower)
                                                │
   AUTOLOADS (état global, vivent toute la partie)
   WorldFlags  GameClock  LawSystem  ScenarioManager  Society  SaveSystem
                                                │
   Tower ── Player ── Hud (CanvasLayer)
     └── FloorLayout[]  (Village, Asile ; un par étage, tous construits au démarrage, empilés en y)
            ├── FloorController (Floor01Village / Floor02Asylum) : scénarios + lois de l'étage
            ├── décor, objets, ressources reflétées (Interactable, ScenarioTrigger, Enemy...)
            └── Inhabitant[]  (corps 3D = marionnettes des Person de Society)
```
Flux logique : **Society** (données) ⟶ décide ⟶ **Inhabitant** (corps) exécute ; **FloorLayout** reflète les **ressources** de Society ;
**LawSystem** applique les lois à tous les corps ; **ScenarioManager** suit les épreuves (remplacé à terme par le Sceau).

## 2. Autoloads (ordre de `project.godot`)
| Autoload | Fichier | Rôle |
|---|---|---|
| `WorldFlags` | `core/world_flags.gd` | flags persistants (`killed_asylum_guru`, `used_forgotten_door`, `current_floor_chaos_level`...). `memories()` donne les phrases du journal. |
| `GameClock` | `core/game_clock.gd` | horloge unique (1 s réelle = 1 min de jeu), compteur de `day`, `sky_color()`, `daylight()`, `absolute_minutes()`, `advance()`. |
| `LawSystem` | `core/law_system.gd` | registre des lois par étage (`register_floor(n, y0, hauteur, lois)`), `floor_at(y)`, `gravity_scale_for(corps)`, `watchers_near(pos, rayon)` (sentinelles éveillées), `observe(loi)`, `note_exploit()`. |
| `ScenarioManager` | `scenario/scenario_manager.gd` | scénarios et conditions (`report`, `discover`, signaux `scenario_resolved`, `floor_cleared`). **Sera remplacé par le Sceau** (voir roadmap A1). |
| `Society` | `society/society.gd` | société simulée (voir §5). |
| `SaveSystem` | `core/save_system.gd` | JSON `user://save_slot_1.json`, `VERSION = 3`, `pending` (état à appliquer au prochain chargement de la Tour), `new_game()`. |

## 3. Le monde : Tower et FloorLayout
**`Tower`** (`world/tower.gd`) construit tous les `FloorLayout` au démarrage, les empile : `layout.position.y = base_y`,
`base_y(n+1) = base_y(n) + hauteur(n) + SLAB(1.0)`. Les coordonnées d'un décor sont **locales à l'étage** (sol à y = 0).
- **L'Axe** : `Tower.AXIS = Vector2(-14, -16)` : (x, z) commun à tous les lieux d'ascension/d'arrivée. La Chambre du Sceau de
  l'étage 1 est sous la maison de l'Ancien, exactement sous la cabine d'arrivée de l'étage 2 (testé).
- **Étage actif** : déduit de l'altitude du joueur (`LawSystem.floor_at`). `_set_active(n)` appelle `layout.set_active()` :
  il **gèle uniquement les éléments dynamiques** (ennemis, `FloorController`, habitants) des étages inactifs.
  ⚠ N'utilisez jamais `process_mode = DISABLED` sur un layout entier : cela désactive aussi ses collisions statiques
  (la dalle d'un étage est le sol du suivant) ; le joueur tombait à travers (bug déjà vécu).
- **Voyages** : `Tower.travel(dest, yaw, style)` (`"fade"` ou `"ascend"`) immobilise le héros (`Player.frozen`), joue
  `Hud.transition(style, on_mid)` et le déplace au moment le plus opaque. Les layouts émettent `travel_requested(local, yaw, style)`
  et `ascend_requested`. `_ascend_from(n)` emmène à l'étage n+1 sur l'Axe (ou affiche « pas encore bâti »).
- **Environnement** : à chaque frame, `FloorLayout.apply_environment(env, sun)` de l'étage actif règle soleil/ambiance/brouillard ;
  sous terre (cave) on force ni soleil ni ciel. Le village règle la couleur du faux ciel (plafond) sur `GameClock`.
- **Mort** : fondu, `Society.simulate(120)` (la société vit 2 h), chaos +1, retour au pied de l'étage actif.

**`FloorLayout`** (`world/floor_layout.gd`, base) cycle de vie dans `_ready` : enregistre les lieux de Society
(`_society_places()`), construit la coque (`_build_shell` : sol/plafond-ciel), appelle `_build()` (contenu), enregistre les lois dans
`LawSystem`, `spawn_people()` (un `Inhabitant` par `Person` de l'étage), `_sync_world()`. Ensuite `_process` resynchronise
`_sync_world()` chaque seconde **si l'étage est actif**. Aides : `track(node, uid)` (objet « consommé » sauvegardé),
`_assign(habitant, "strike|carry|grab|tend", cible, dest, réplique)` (envoie un habitant agir visiblement, réserve la cible),
`_puppet(person_id)`, `_free_of(liste)`.
Hooks à surcharger : `_build`, `_society_places`, `_sync_world`, `_on_world_effect`, `_on_floor_cleared`, `spawn_point`, `arrival_point`,
`apply_environment`, `_floor_material`, `_ceiling_material`.

**`VillageLayout`** (étage 1, 14 m de haut, 290 × 290 m dont 240 jouables) : faux ciel, montagnes (N/O/E) + Bout du monde (S, cascade,
brume, Fiole de la cascade), maisons/fontaine/arbres Kenney, labyrinthe-prototype de haies (anneaux d'arbres), Puits, Fosse, ferme/grange,
**trappe** (Interactable « Descendre dans la cave ») → **Chambre du Sceau** (sous le sol, y = −8, sur l'Axe) avec le Sceau (disque + piliers
rouge/vert) et la sortie « Remonter ». Ressources reflétées : `pit_monsters`, `farm_crates`, `relic_at_well`, `elder_pass_ground`.
**`AsylumLayout`** (étage 2, 3,6 m, 62 × 62 m en preuve de concept) : murs modulaires Kenney, lits/patients (`asylum_patients`), Gourou, bureau,
pièces éclairées (refuge : la folie reflue), « porte des Oubliés » (encore liée à 100 % de folie : à refaire), **cabine d'arrivée sur l'Axe**.

## 4. Lois, scénarios, Sceau
- `FloorLaw` (`laws/floor_law.gd`) : `effect` ∈ {`NONE`, `GRAVITY_INVERT`, `SEALED_EXIT`}, `active_hours`, `exploits: Array[LawExploit]`.
  `LawExploit` (`laws/law_exploit.gd`) : conditions combinables (`required_items`, `min_sanity`, `hour_range`, `required_flags`, `max_watchers`).
- `FloorController` (`floors/floor_controller.gd`) : `begin()` démarre le 1er scénario à l'arrivée du joueur (une fois), `attempt_exit(player)`
  évalue la loi `SEALED_EXIT` + failles, `is_cleared()`. `Floor01Village` (scénario `village_trials`, loi `village_gate_sealed` avec failles
  « porte sans surveillance » (`max_watchers = 0`) et « laissez-passer de l'Ancien »), `Floor02Asylum` (folie, hallucinations, loi gravité à minuit
  sur tous les corps, loi de sortie). `Floor03Canopy` est un **stub** sans usage.
- `Scenario` / `WinCondition` (`scenario/`) : conditions avec `target`, `progress`, `clue`, `hidden`, `discovered`.
  **Dette** : le HUD les affiche encore comme des pistes et un toast annonce « Épreuve résolue » (contraire à l'invariant n°2) ; ils seront
  remplacés par le système Sceau/verrous (roadmap A1/A2). La sortie d'étage passe aujourd'hui par `FloorController.attempt_exit`
  appelé depuis `VillageLayout._on_seal`.

## 5. La société (`scripts/society/`, `scripts/agents/`)
- **`Person`** (`person.gd`, `RefCounted`) : tempérament (sociabilité, courage, curiosité), habitudes (`routine` : tranches `{from,to,act,place}`),
  état (activité, lieu, énergie, besoin social, humeur, confiance envers le joueur `trust`), `desires`, `rel` (affinités), `knows`
  (fait → discrétion propre à cette personne), `heard`, `carrying`. Textes de voix (salut, esquives, barks).
- **`Cast`** (`cast.gd`) : le contenu : `people()` (6 personnes : Ancien, Enfant, Chasseur, Fermière, Garde, Infirmière), `FACTS`, `DEEDS`
  (actes du joueur), `RESOURCES` (+ cadence de renouvellement), `WORK_EFFECTS` (quand une personne exerce une activité à un lieu, elle consomme
  une ressource), `SUBJECTS` (sujets de « Demander à propos de »).
- **`Society`** (autoload) simule **tous les étages** par pas de 10 min de jeu (`_step`) : besoins ⟶ décision par **utilité** (`_decide` : habitude,
  fatigue, peur, désirs, solitude, caprice ; aléas volontaires) ⟶ effets sur la Tour (`_apply_effects`) ⟶ renouvellement (`_regen`) ⟶ rencontres
  (`_social` : amitiés, querelles, **ragots** `_gossip`). API : `person`, `res`, `take_resource`, `player_deed(kind)` (confiance + réputation par
  ouï-dire), `wake`, `on_threat`, `begin_conversation`, `small_talk` (ne livre jamais de secret), `ask(pid, sujet)` (divulgation selon
  `trust >= discrétion*60 − humeur*8`), `simulate(minutes)`, `replan()`, `to_dict/from_dict`. Signaux : `social_event`, `world_effect`,
  `gossip_told`, `overheard`, `fact_learned`, `item_given`.
- **`Inhabitant`** (`agents/inhabitant.gd`, `CharacterBody3D`) : marionnette d'une `Person` (`person_id`). Lit `Society.person().activity/location`
  et l'exécute : marche, dort (visible, couché + « Zzz »), se cache chez lui (`HOME`, invisible), fuit les monstres (`FLEE`, panique contagieuse),
  parle (`conversation_requested`), `start_task(kind, cible, dest, réplique)` pour agir visiblement (`strike`, `carry`, `grab`, `tend`),
  `chat_with(autre)` pour les conversations face à face, ragots audibles de près. Il subit les lois comme un corps (gravité).
  `freeze()/thaw()/catch_up()` : hors étage actif la personne continue de vivre sans corps ; au retour on replace le corps selon son plan.
- **Ressources** : `Society.resources` (ex : `pit_monsters`) évoluent hors champ ; le layout s'en fait le **reflet** (`_sync_world`) et anime
  l'action quand l'étage est actif (cibles marquées `reserved` pour ne pas être retirées deux fois).

## 6. Joueur, combat, UI
- `Player` (`player/player.gd`) : modèle animé Kenney, caméra bras à ressort, attaque de mêlée, `nearest_interactable()`, `frozen`, `shake()`,
  `law_context()` (objets, folie), gravité pilotée par `LawSystem`. Actions d'entrée créées par code (`_ensure_actions`).
- `Enemy` (`enemies/enemy.gd`) : poursuite simple, subit les lois, `despawn()` (retrait « par le monde », pas un meurtre du joueur).
  `HealthComponent`, `Phantom` (hallucination).
- `Interactable` (Area3D, touche E), `ScenarioTrigger` (zone de déclenchement), `Door` (**inutilisé** depuis la géographie close).
- `Hud` (`ui/hud.gd`) : PV, heure, étage, invite d'interaction, notifications, dialogues à choix (« Bavarder », « Demander à propos de... »),
  journal (Tab/J), pause (Échap : sauvegarder/charger), voile d'ascension (shader), fondu de mort. États modaux : `""`, `dialogue`, `journal`, `pause`
  (mettent l'arbre en pause, souris visible). `UiTheme` : police Lilita One + styles.

- `MainMenu` (`ui/main_menu.gd`, scène `menu.tscn`) : Nouvelle partie (`SaveSystem.new_game()`), Continuer (charge le slot 1 si présent), Quitter.
- `WorldUtil` (`world/world_util.gd`, `RefCounted` statique) : briques de décor : `box`, `checker` (damier en coordonnées monde), `slab` (dalle avec trou),
  `ramp`, `wall_line` (mur modulaire Kenney), `invisible_wall`, `mountain`, `waterfall` et `mist` (shaders), `marker`, `unshaded`.

## 7. Sauvegarde
`SaveSystem.save_game(slot, world)` écrit `{version, world, flags, scenarios, clock, laws, society}`. `world` (`Tower.collect_save`) = joueur
(position, lacet, PV, inventaire) + par étage `{consumed, ctrl}`. Charger = `SaveSystem.pending = données` puis `reload_current_scene()`;
`Tower._ready` consomme `pending`. Les clés `StringName` sont converties en `String` ; les entiers JSON reviennent en `float` (reconvertir avec `int()`).
Changer le format ⟹ incrémenter `VERSION`.

## 8. Assets (`scripts/world/assets.gd`)
Catalogue `PATHS` (clé → `.glb`). `Assets.place(clé, taille, "height"|"width")` mesure l'AABB réel et **met à l'échelle/recentre** (pied à l'origine) ;
`prop(...)` ajoute une collision boîte ; `tint()` teinte. `CharacterModel` : modèle animé (idle/walk). Repli : boîte grise si un fichier manque.
Les `.glb` Kenney exigent leur `Textures/colormap.png` dans le même dossier (un dossier par kit : le colormap diffère). Voir `CREDITS.md`.

## 9. Recettes d'extension
- **Nouvelle personne** : ajouter un `_person({...})` dans `Cast.people()` (étage, routine, désirs, relations, `knows`, voix) et ses lieux dans
  `_society_places()` du layout. Aucun autre code : `spawn_people()` crée le corps.
- **Nouveau fait / secret** : entrée dans `Cast.FACTS` (`subject`, `text`, éventuellement `discovers`, `gives`, `while_res`), puis l'ajouter au `knows`
  des détenteurs avec leur discrétion (0 = public, 0.95 = presque jamais). Ajouter le sujet dans `Cast.SUBJECTS`.
- **Nouvelle ressource du monde** : `Cast.RESOURCES`, un `WORK_EFFECTS` (qui l'agit), un reflet dans `_sync_world()` du layout, éventuellement
  une animation dans `_on_world_effect`.
- **Nouvelle loi** : un `FloorLaw` dans le contrôleur d'étage ; si c'est un effet physique, l'appliquer dans `LawSystem` (ex : `gravity_scale_for`).
- **Nouvel étage** : une classe `XxxLayout extends FloorLayout` (hauteur, empreinte, `arrival_point` sur l'Axe) + un `FloorXxx extends FloorController`,
  l'ajouter à la liste dans `Tower._build_floors`.
