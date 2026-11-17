# CLAUDE.md : à lire en premier (instructions de projet pour toute nouvelle session)

> Ce fichier est un **guide de projet**, pas une consigne système. Si la session a ses propres instructions
> (outils disponibles, format de réponse...), elles priment. Lisez ensuite `docs/HANDOFF.md`.

## Le projet en 5 lignes
« The Tower » (titre provisoire) : Action-RPG solo en 3ème personne, **Godot 4.3, GDScript**, dépôt open source.
Un seul héros humain gravit une Tour de 100 étages (le MVP en vise 5) ; chaque étage est un monde clos sous un
faux ciel, peuplé d'une **société simulée** qui vit sans le joueur. L'intelligence du joueur (observer, déduire,
trouver les failles) prime sur la puissance brute. Le but d'un étage n'est **jamais annoncé** : on le devine.
État : étage 1 (Village) et étage 2 (Asile) jouables en preuve de concept ; 106 vérifications automatiques passent.

## Où lire quoi (ordre conseillé)
1. `docs/HANDOFF.md` : état, reprise en 10 minutes, pièges, dette technique.
2. `docs/ARCHITECTURE.md` : modules, flux de données, recettes d'extension.
3. `docs/DESIGN_BIBLE.md` : la vision (copie du document partagé ; **la version vivante fait foi**, voir plus bas).
4. `docs/ROADMAP_TRANCHE_A.md` : les prochaines étapes, détaillées au niveau fichier et test.
5. `docs/WORKFLOW_TOOLS.md` : comment travailler (sandbox, Godot, captures, document partagé, ce qui peut manquer).
6. `docs/DEV_LOG.md` : l'historique des décisions et des pivots, avec leurs raisons.

## L'utilisateur
- Francophone. **Répondre en français.** Il lit souvent sur mobile : réponses courtes, en tête la réponse, pas de mur de texte.
- Goûts déclarés : l'open source ; PHP est son langage préféré (mais Godot n'accepte pas PHP : GDScript ici).
- Il valide par « Continuer » / « Va y » : cela veut dire **poursuivre de façon autonome le plan en cours**, pas redemander.
- Il apprécie l'honnêteté sur les limites et les bugs trouvés. Ne jamais survendre : dire ce qui est testé et ce qui ne l'est pas.
- Il tranche la conception (voir la liste des décisions, section 18 du bible). Ne pas réinventer ce qui est tranché ;
  proposer des options chiffrées pour ce qui est ouvert.

## Invariants de conception (ne pas casser)
1. **Solo strict** : un seul héros contrôlé, pas de gestion d'équipe ni de ville.
2. **Jamais d'objectif écrit.** Le journal consigne des faits appris, pas des tâches. (Le code actuel en affiche encore :
   c'est de la dette, à supprimer à l'étape A2.)
3. **Aucun verrou à élément unique** : un Sceau a plusieurs verrous de natures différentes et plusieurs routes.
4. **Les habitants ignorent les lois de la Tour** (sauf étages thématiques) : ils ont des faits, des rumeurs, des traditions.
   Le terme « loi » n'apparaît jamais dans leurs répliques. Côté joueur on parle de « phénomènes ».
5. **Le savoir se mérite** : chaque secret a un seuil de confiance propre à chaque détenteur ; « Bavarder » ne livre jamais un secret.
6. **Même loi pour tous les corps** d'un étage (le joueur, les monstres, les habitants subissent la même gravité inversée).
7. **Rien n'est définitivement perdu** : toute ressource clé reste récupérable autrement (ex : l'Enfant prend la relique : on la lui demande).
8. **Étages empilés, ascensions cachées, alignées sur l'Axe** (x,z communs) ; aucun escalier visible de l'extérieur.
9. **Une seule horloge** (`GameClock`), une seule mémoire (`WorldFlags`), un seul moteur de lois (`LawSystem`).
10. **Les habitants vivent hors champ** : `Society` simule tous les étages ; les corps 3D ne sont que des marionnettes.
11. **Graphismes = preuve de concept** (volumes simples, modèles CC0). Ne pas sur-investir dans l'esthétique ; la performance a de la marge.
12. Chaque fonctionnalité a **un test** dans `tests/smoke_test.gd`. Les tests ne trichent pas (pas de touches de debug dans le jeu).

## Commandes essentielles (détails dans docs/WORKFLOW_TOOLS.md)
```bash
# 1) récupérer le projet depuis GitHub (source de vérité)
git clone https://github.com/Lasertie/the_tower.git
# ou, si le bac à sable a été réinitialisé et qu'il n'y a pas de git, utiliser l'archive :
cd /home/claude && unzip -q /mnt/user-data/outputs/the_tower.zip
# 2) Godot 4.3 (non conservé entre sessions)
curl -sSL -o /tmp/godot.zip https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_linux.x86_64.zip && unzip -qo /tmp/godot.zip -d /tmp && chmod +x /tmp/Godot_v4.3-stable_linux.x86_64
# 3) importer
cd /home/claude/the_tower && rm -rf .godot && timeout 200 /tmp/Godot_v4.3-stable_linux.x86_64 --headless --path . --import
# 4) tests (rendu logiciel requis : les collisions viennent des modèles 3D)
timeout 295 xvfb-run -a -s "-screen 0 1280x720x24" /tmp/Godot_v4.3-stable_linux.x86_64 --rendering-driver opengl3 --path . res://tests/smoke_test.tscn
```
Résultat attendu : `Échecs : 0` et 106 lignes `OK`.

## Règles de travail
- Après chaque modification : réimporter, relancer les tests, **regarder une capture** si c'est visuel (`tests/shot_*.tscn`).
- Si le format de sauvegarde change : incrémenter `SaveSystem.VERSION` et le dire à l'utilisateur (anciennes sauvegardes invalides).
- Livrer par un zip dans `/mnt/user-data/outputs/the_tower.zip` (sans `.godot/`), puis `present_files`.
- **Toujours mettre à jour `docs/`** (HANDOFF, ARCHITECTURE, DEV_LOG) dans le même zip que le code.
- Le document de conception partagé (Claude Doc) est la **source de vérité de la vision** :
  projet `b73c8c27-a053-4f9c-9d75-d0b4754c3e83`, https://claude.ai/artifact/PdMeFY76UsSMszFcwJh42E .
  `docs/DESIGN_BIBLE.md` n'en est qu'un instantané ; en cas d'écart, croire le document vivant, puis réexporter.
- Dire explicitement ce qui n'a pas été testé à la main (aucune session n'a « joué » le jeu : tout est vérifié par
  tests automatiques et captures d'écran).
