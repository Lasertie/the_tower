# La Tour — Bible des étages (plan de conception v1)

*Plan de travail des étages 1 à 5, bâti sur la base actuelle (société simulée, lois communes, escaliers physiques). Tout est sujet à amélioration : ce document sert à trancher avant de coder.*

## 1. Ce que ce plan change

- **Fin du guidage.** Plus de liste d'objectifs, plus de « épreuve résolue ». Le joueur observe, déduit et vérifie comment monter.
- **Sortir d'un étage devient un Sceau à plusieurs verrous** de natures différentes. Aucun objet, aucun acte ne l'ouvre seul, s'il n'est pas assez conséquent.
- **Les reliques et trophées facilitent, ils n'ouvrent pas.** Ils baissent un seuil, révèlent une information ou ouvrent une route.
- **Les espaces deviennent imposants** : un Dédale de haies à l'étage 1, un Asile qui est lui-même un immense labyrinthe à l'étage 2.
- **Un univers cohérent** : tout découle d'une idée unique, la *Clause* (section 3).
- **La difficulté est systémique** (spec d'origine) : chaque étage ajoute des mécanismes à comprendre, pas des points de vie.

## 2. Principes directeurs

1. **Observer, déduire, prouver.** La Tour n'explique jamais ses règles.
2. **Jamais d'objectif écrit.** Le journal consigne ce que le héros a *vu et entendu*, jamais ce qu'il doit faire.
3. **Aucun verrou à élément unique.** Au moins deux routes, et au moins deux verrous par route.
4. **Triple indice.** Toute solution est découvrable par l'environnement, par un témoignage mérité et par la réaction du Sceau. Toute information essentielle a au moins deux sources indépendantes, pour qu'un joueur ne soit jamais coincé par un PNJ absent ou endormi.
5. **Rien n'est définitivement perdu.** Si un habitant prend la relique, on peut la lui demander, la lui acheter ou la lui reprendre.
6. **Les habitants vivent sans nous** : ils peuvent aider, gêner, devancer le joueur.
7. **Savoir n'est pas divulguer.** Un habitant ne livre un secret que s'il a une raison (confiance, dette, intérêt, moment propice).
8. **Chaque route laisse une Marque** durable (section 3) qui change le monde des étages suivants.
9. **Complexité plutôt que puissance** : l'étage 5 n'est pas plus « gros » que le 1, il est plus riche en systèmes qui interagissent.
10. **Un seul héros**, jamais de gestion d'équipe ni de ville. (dans le jeu de base)

## 3. Cosmologie : la Tour est un Registre

**Idée unificatrice : la Clause.** La Tour est un registre à étages ; chaque étage est un chapitre écrit selon des *clauses*.

- **Clauses de régime** : ce que nous appelons aujourd'hui les « lois » (gravité inversée à minuit, pas de feu, la folie...).
- **Clauses de sortie** : les Sceaux qui ferment l'escalier de chaque étage.
- **Les habitants vivent sous des clauses qu'ils ne lisent pas.** Ils n'ont que des *traditions* : « on ouvre la porte à l'aube » est un usage qui épouse mal une vraie clause (qui parle, elle, de ciel rouge).
- **Étages thématiques.** Là où la culture *est* la lecture d'une clause, les habitants la connaissent : les elfes de la Canopée (le feu interdit est une religion), l'Archipel (le Code des pirates), le Champ de bataille (la Ligne). Même eux la connaissent mal : ils ont **la lettre, pas l'esprit**. Cherchez ce que la clause ne dit pas.
- **Les Glyphes** sont l'écriture de la Tour, gravés sur les sceaux et les portes. Le héros apprend un vocabulaire par étage, par observation (la main ouverte = consentement, l'étoile = mérite, le soleil = moment...). C'est aussi l'interface diégétique du Sceau.
- **Les Marques** : ce que la Tour inscrit sur le héros selon ses actes (*Reconnu*, *Intrus*, *Fou*, *Sang*, *Parjure*...). Elles changent les réactions des habitants et certaines clauses.

## 4. Géographie : mondes clos et ascensions cachées

Chaque étage est un monde clos sous un faux ciel, sans escalier visible de l'extérieur. Les étages restent superposés dans le monde du jeu (mêmes lois, même horloge), mais rien n'en transparaît.

- **Faux ciel conservé.** Le plafond de chaque étage reste un ciel peint qui suit l'horloge (aube orangée, nuit profonde).
- **Plus de murs, plus de rampe.** Les murailles latérales sont remplacées par des **montagnes** ou par **le Bout du monde** : un rebord où l'eau tombe dans le vide. L'escalier monumental et le trou dans le plafond disparaissent.
- **Ascension cachée.** Chaque étage a un lieu d'ascension à l'intérieur d'un bâtiment ou d'un décor clos. Il joue une animation de montée (fondu, grondement, caméra qui s'élève à travers des strates lumineuses, environ 6 secondes), puis dépose le héros à l'entrée de l'étage suivant. Étage 1 : la **Chambre du Sceau**, sous la maison de l'Ancien. Étage 2 : un ascenseur de service dans le Sas du Directeur. Étage 3 : l'intérieur de l'Arbre-Mère. Étage 4 : un tunnel creusé dans la montagne du Col. Étage 5 : une colonne d'eau au cœur de la Brèche. **L'Axe** : tous ces lieux d'ascension sont superposés sur un même axe vertical. L'arrivée d'un étage se trouve toujours juste au-dessus du départ de l'étage précédent (la Chambre du Sceau de l'étage 1 est exactement sous l'arrivée de l'étage 2).
- **Les Bords et leurs trésors.** Au Bord de chaque étage se cache un objet qui servira plusieurs étages plus tard. À l'étage 1, la **Fiole de la cascade** : une eau qui tombe sans fin. Les eaux de tous les Bords retombent dans la mer de l'étage 5 (c'est elle qui les recueille) ; la fiole y sert à calmer le maelström, ou à révéler le courant qui mène à la Brèche. Les trésors des Bords des étages 2 à 4 restent à écrire.
- **Budget graphique et de performance.** Les graphismes restent une preuve de concept (volumes simples, instanciation en masse) : cela autorise des espaces bien plus vastes (un Dédale de 164 m, un Asile de 320 m). Les vrais modèles viendront plus tard.
- **Avantage technique.** L'animation d'ascension masque le chargement de l'étage suivant et le déchargement du précédent.

## 5. Le Sceau (système central)

**Anatomie.** Un Sceau a 3 ou 4 *verrous*. Une *route* est une combinaison de verrous satisfaits par des moyens précis. Le Sceau s'ouvre quand une route est complète au moment où le héros se présente.

**Six types de verrous** (vocabulaire commun à tous les étages) :

1. **Consentement** : confiance ou rang auprès de personnes ou de factions.
2. **Mérite** : la preuve d'un acte difficile (trophée, exploit visible).
3. **Moment** : une fenêtre horaire, une météo, une phase.
4. **Regard** : personne ne voit... ou, au contraire, un témoin doit voir.
5. **État** : l'état du héros (lucidité, blessure, charge portée).
6. **Offrande** : un coût à payer (un objet, un allié, un souvenir, une Marque).

**Routes types.** *Honneur* (légitime, lente), *Ruse* (furtive, risquée), *Force* (violente, Marque de Sang), *Pacte ou Folie* (marginale, coûteuse).

**Facilitateurs** (jamais des clés) : des outils (craie, serpe, lanterne), des documents, des alliés, du savoir. Exemple : la relique du Puits révèle l'état des glyphes à son porteur et fait gagner la confiance de ceux qui la vénèrent, mais n'ouvre rien.

**Retour diégétique** (sans texte) : glyphes qui s'allument, pierre tiède, bourdonnement, réaction des PNJ. Trois niveaux d'aide réglables : *0 pur* (aucun retour), *1 glyphes* (par défaut aux étages 1-2), *2 résonance* (seulement avec la relique, étages suivants).

**Garde-fous, testés automatiquement.** Un solveur vérifie que chaque Sceau a au moins une route atteignable depuis n'importe quel état de partie ; aucune ressource clé n'est perdable définitivement sauf cas spécial ; aucun verrou n'est satisfait par un seul objet ; le journal ne contient aucun texte d'objectif.

## 6. Journal : la fin du guidage

- **Supprimé** : la liste des conditions, les compteurs (0/5), les notifications « épreuve résolue », les noms de zones à visiter.
- **Conservé et enrichi** : *Observations* (ce que le héros a constaté), *Témoignages* (qui a dit quoi, avec la confiance qu'on lui accorde), *Rumeurs*, *Lieux visités* (sans carte), *Marques, stats du joueur*.
- **Nouveau, optionnel** : un *Carnet* où le joueur épingle des indices et les relie entre eux. C'est le support de la déduction, pas un guide.
- Les « scénarios » internes restent un suivi invisible pour le moteur.

## 7. Société : extensions nécessaires

- **Requêtes.** On peut demander un service (« venez à l'aube », « escortez-moi »). Acceptation selon confiance, humeur, intérêts et relations ; l'habitant planifie réellement le service.
- **Secrets multi-conditions.** Pas seulement de la confiance : un gage, un moment propice, l'absence de témoin, une dette.
- **Réciprocité.** Les habitants demandent aussi : un service rendu crée une dette qu'ils peuvent invoquer plus tard.
- **Rangs.** Étranger, Hôte, Ami, Frère : des paliers d'accès, plus lisibles que des nombres.
- **Factions** (dès l'étage 3) : relations entre groupes, loyauté interne, état de guerre (étage 4), hiérarchie de bord et mutinerie (étage 5).

## 8. Étage 1 — Le Seuil (refonte du Village)

**Thème** : la Tour vérifie si l'on peut *appartenir*, *prouver* et *saisir l'occasion*. **Systèmes appris** : horloge et ciel, réputation, écologie des ressources, surveillance, Sceau.

**Espace.** Un étage de 260 × 260 m (au lieu de 100) : village, champs, bois, marais, Puits, Fosse, grange et le Dédale. Sous un faux ciel, sans muraille : trois côtés bordés de montagnes, le quatrième ouvert sur le Bout du monde (voir section 4). Le Sceau n'est plus un escalier visible mais une Chambre du Sceau sous la maison de l'Ancien.

**Le Dédale des Haies** (imposant et complexe) :

- Grille de 41 × 41 cellules de 4 m (164 × 164 m), haies de 7 m, généré à partir d'une graine propre à la partie (le même labyrinthe à chaque rechargement).
- Arbre couvrant, 15 % de boucles, trois clairières à repères uniques (statue, arbre mort, fontaine), un cercle intérieur.
- **Aucune carte, aucune mini-carte.** On s'oriente avec le soleil (l'angle des ombres suit l'horloge), la cloche du village (qu'on entend plus ou moins) et de la **craie** (outil de la ferme) pour marquer les carrefours.
- **Haies fragiles** (10 % des murs) : la **serpe** les coupe et elles repoussent en un jour. Un raccourci à découvrir.
- **Vie dedans** : un ermite, le Gardien des Haies (il connaît le chemin et un secret, mais craint les bêtes), des égarés (le fils du forgeron, perdu depuis trois jours, a sa propre histoire) et une Bête des Haies qui patrouille, plus dangereuse la nuit.
- Première traversée : 10 à 25 minutes. Au centre, la **Bannière**, preuve visible de mérite.

**Le Puits** (petit donjon vertical lié au temps) : le niveau d'eau monte et descend toutes les 6 heures ; la relique ne s'atteint qu'à marée basse. L'Enfant la convoite et connaît un passage d'enfant (une faille) : il peut la prendre avant le joueur.

**La relique, la « Lanterne d'écho »** (facilitateur) : elle fait voir le *passé récent d'un lieu*, sous forme de silhouettes qui rejouent ce que la société y a vécu ces dernières heures (le garde qui s'assoupit, l'Ancien qui descend à la cave, l'Enfant et son passage secret). Elle n'ouvre rien, mais elle change l'enquête : au lieu d'attendre l'aube dans le noir, on regarde la nuit d'hier. Les échos sont partiels et bruités, et la lanterne a une charge limitée qui se recharge au Puits. *Dilemme* : l'utiliser, l'offrir à l'Ancien (+40 de confiance) ou la rendre à l'Enfant (il révèle son passage secret) ; la donner, c'est renoncer aux échos. *(Usage à valider : décision 2.)*

**Le Sceau de la Chambre** (deux verrous, ni écrits ni annoncés) :

- **Consentement** : l'Ancien, à confiance d'au moins 40, sans rancune majeure (< −15) chez l'Enfant, la Fermière, le Chasseur ou le Garde.
- **Mérite** : la Bannière du Dédale, ou cinq cornes de la Fosse, ou une autre épreuve de même poids.

Routes : **Honneur** (les deux verrous : l'Ancien descend à la cave avec le héros et ouvre le Sceau, sur *requête*) ; **Ruse** (laissez-passer de l'Ancien **et** cave sans regard : le Garde qui veille la maison doit dormir, être parti déjeuner ou avoir fui, **et** l'Ancien doit être absent ; Marque *Intrus*). La sieste du garde reste un indice, plus la clé ; l'Ancien ne divulgue le rite qu'à très haute confiance ; l'Ermite en sait un fragment.

**Marques et suites.** *Reconnu* : accueil plus chaleureux à l'étage 2. *Intrus* : les sentinelles des étages suivants surveillent davantage et le chaos monte.

## 9. Étage 2 — L'Asile (un immense labyrinthe)

**Thème** : *lucidité* et *connaissance incertaine*. Régimes : la folie, la gravité inversée à minuit, des lumières qui vacillent avec la folie. Les habitants ignorent les lois, sauf le Directeur et l'Archiviste (thématiques).

**Espace.** Un complexe de 320 × 320 m, environ 200 salles, **trois niveaux** : sous-sols (chaufferie, morgue, tunnels), rez-de-chaussée, combles. Ailes : Accueil (pivot), Médicale, Administration, Cellules (aile fermée), Réfectoire et cuisines (où sont faites les réunions du Culte du Gourou).

**Fabrication.** Un *graphe de pièces* : des salles repères écrites à la main, reliées par des couloirs générés avec des boucles, graine propre à la partie. Les plans muraux sont des **documents de fiabilité variable** : certains faux, d'autres anciens, d'autres partiels. On reconstitue la carte par recoupement, sans mini-carte. L'Archiviste connaît le plan vrai, mais ne le donne qu'à qui il fait confiance.

**Effets avancés (prototype d'abord).** Vous avez validé un Asile non euclidien poussé. Pistes, par ordre de risque : (1) *couloirs qui se replient* : la boucle déplace discrètement le héros quand il franchit une porte ou tourne le dos ; (2) *pièces plus grandes à l'intérieur qu'à l'extérieur*, par des portails continus entre deux espaces rendus par une vue secondaire ; (3) *portes à destination changeante* selon la folie ou l'heure ; (4) *distorsions de rendu* (murs qui ondulent, aberration chromatique, couloirs qui s'allongent) et sons spatialisés trompeurs. On prototype (1) et (2) avant tout autre contenu de l'étage : si les portails sont trop coûteux, (1), (3) et (4) suffisent à désorienter.

**La boucle.** Passer trois fois dans un couloir sans tourner le « replie » : on revient à son point de départ. C'est le signal d'être perdu, et un apprentissage (casser la boucle).

**La folie déforme.** À partir de 40 %, des portes fantômes et de faux murs apparaissent (retour visible, la physique reste cohérente). À 100 %, le héros sombre : échec de la partie. *(Seuil et sanction à confirmer.)*

**Lumière.** L'Asile est sombre ; une lanterne à autonomie limitée et l'eau des fontaines fixent le rythme des explorations.

**Le Sceau (le Sas du Directeur)** :

- **Route Lucide** : *État* (folie ≤ 30 au seuil) + *Dossier de sortie* en trois pièces (Cachet de l'Administration, Ordonnance de l'Infirmerie, Clé du Directeur), chacune gardée dans une aile et par ses propres personnes + *Moment* (hors minuit et hors du chant du Gourou).
- **Route des Oubliés** : la **Porte des Oubliés est cachée**. Elle n'apparaît, à un endroit prévisible du labyrinthe, que si le héros porte un objet précis (à trouver) ; personne n'y entre sans l'avoir décidé. Elle mène à *l'Envers* (l'asile en miroir, court, à logique de rêve). *Offrande* : un souvenir, c'est-à-dire qu'une relation s'efface : un habitant de confiance ne vous reconnaît plus (variante à valider : quelques pages du journal s'effacent). Marque *Fou* permanente (hallucinations aux étages suivants).
- **Route du Culte** : se faire acolyte du Gourou et l'accompagner à minuit ; en échange, le Culte vous protège, vous ouvre le caveau du Gourou et vous épargne ses chants. Route mise en attente de façon propre (interrupteur de fonctionnalité) tant que les autres ne sont pas stables. Marque *Parjure*.

**Facilitateurs** : tuer le Gourou (fait cesser les chants et facilite la navigation, mais déclenche la Marque *Sang* et des cauchemars à l'étage 3) ; soigner les patients (réputation, et un ancien patient devient allié à l'étage 4) ; l'Infirmière sait que « tout se retourne à minuit » mais ne le dit qu'à une confiance élevée.

## 10. Étage 3 — La Canopée

**Thème** : *le légalisme* (la lettre contre l'esprit). Les elfes tiennent le « pas de feu » pour sacré, mais ne comprennent pas ses limites : la clause interdit la *flamme*, pas la *chaleur*. Une « braise de givre » des strates profondes en est la faille.

**Espace.** Cinq strates verticales : Sol (ombre), Fût, Couronne, Haute canopée, Cime. Lumière et température différentes à chaque strate ; bioluminescence la nuit, vent selon l'horloge.

**Société.** Trois clans (Gardiens du Feu froid, Tisseurs, Exilés) avec relations croisées et rangs d'accès. Choix moraux : **pacte, combat ou corruption** d'un clan.

**Sceau (le Passe de Cime)** : *Consentement* du Conseil (ou corruption d'un clan, ou mort de la Reine : Marque *Sang*) + *Ascension* verticale (aucune téléportation) + *Moment* (nuit de floraison) + *Offrande* (une flamme : renoncer au feu pour la suite).

**Systèmes appris** : verticalité et chute, vent, diplomatie à plusieurs factions, lecture littérale des clauses.

## 11. Étage 4 — Le Champ de bataille

**Thème** : *la guerre comme système*. **Murim** contre **Géants**, deux codes thématiques (le duel lie ; la taille détermine le passage). Une **simulation de front** : l'avancée de la ligne dépend de l'approvisionnement, du moral et du sabotage, tous gérés par la société simulée.

**Sceau (le Col)** : *Consentement* double (une trêve, ou un sauf-conduit d'un camp) + *Regard* (traverser la Ligne sans être vu, ou être vu d'un témoin neutre) + *Moment* (accalmie, tempête ou nuit).

**Routes** : allié des Murim ; allié des Géants ; neutre (une faille : les Géants ne voient pas les petites choses, les Murim ne passent pas l'ombre des Géants). L'ancien patient de l'Asile intervient ici.

**Systèmes appris** : guerre de factions, escortes, infiltration à grande échelle, conséquences sur la ligne de front visibles dans le monde.

## 12. Étage 5 — L'Archipel (et boss du MVP)

**Thème** : *la navigation et la hiérarchie*. Régimes : marées et vents cycliques ; le Code des pirates, lu à la lettre.

**Espace.** Un océan, des îles dispersées et secrètes, des brumes. On navigue aux étoiles et au soleil (même principe qu'au Dédale) ; des fragments de carte se recoupent comme les plans de l'Asile.

**Société.** La flotte hiérarchisée (Capitaine, Quartier-maître, Bosco, équipage) avec loyautés et mutinerie simulées.

**Sceau (la Brèche, un maelström)** : *Cap* (la bonne route, une nuit d'alignement d'étoiles) + *Flotte* (un navire capable de passer) + *Capitaine* (duel, mutinerie ou paiement du Code). **Boss** : le Capitaine sur son vaisseau amiral, en plusieurs phases, dont une qui exige de lire le Code à la lettre.

## 13. Progression du héros (statistiques)

**Principe.** Les statistiques ne s'achètent pas : elles *se forment* par les actes. Chaque action du joueur émet des *pratiques* (courir, grimper, esquiver, se taire, mentir, convaincre, observer, tenir dans le noir, supporter la folie...). Les pratiques s'accumulent en silence ; quand un seuil est franchi, une statistique progresse. Rien n'indique à l'avance quelle action fera progresser quoi, et deux joueurs n'auront pas le même héros.

**Flexibilité (le point clé).** Le système est piloté par des données, pas par du code :

- une *statistique* est définie par un identifiant, un nom, les *pratiques* qui la nourrissent (avec des poids), des seuils de progression et ses effets ;
- une *pratique* est une étiquette émise par n'importe quel système du jeu (combat, société, labyrinthe, folie, Sceau). On peut en créer de nouvelles sans toucher aux statistiques existantes ;
- des **statistiques cachées** n'existent pas pour le joueur tant qu'une *action cachée* ne les a pas débloquées. Exemples : tenir une nuit entière dans le Dédale débloque l'*Orientation* ; mentir avec succès trois fois au même habitant débloque la *Duplicité* ; franchir la Porte des Oubliés débloque la *Lecture des Glyphes*. Une statistique débloquée apparaît dans le journal ; avant, rien ;
- un palier peut aussi débloquer une **action** (une manœuvre, une manière d'interagir), pas seulement un chiffre.

**Départ.** Quatre statistiques visibles : Vigueur, Agilité, Acuité, Sang-froid. Statistiques cachées possibles : Orientation, Duplicité, Pas silencieux, Endurance à la folie, Lecture des Glyphes.

**Garde-fous.** Rendements décroissants (pas de répétition mécanique pour farmer), plafonds par arc d'étages, un journal qui décrit les statistiques en mots (« vous vous déplacez plus discrètement ») plutôt qu'en nombres, et des tests de non-régression sur la table des pratiques.

**Lien avec les 100 étages.** Les statistiques doivent rester signifiantes de l'étage 1 à l'étage 100 : les paliers montent par arcs, et les étages demandent des *combinaisons* de statistiques plutôt qu'un total élevé.

## 14. La Tour à 100 étages (architecture de contenu)

L'ambition est de 100 étages. On ne peut pas les écrire à la main un par un : il faut une architecture qui garantisse la qualité à cette échelle. Le MVP reste les étages 1 à 5.

**Arcs.** Dix arcs de dix étages. L'arc 1 (étages 1 à 10) contient les cinq étages du MVP écrits à la main, puis cinq étages complémentaires. Chaque arc a une identité (un régime dominant, une famille de sociétés, une famille de sceaux) et un palier : l'étage 10, 20, 30... est un étage-boss d'arc écrit à la main.

**Trois niveaux de fabrication.**

1. **Étages-repères** (environ 25) : écrits à la main, très singuliers (le Seuil, l'Asile, la Canopée, le Champ, l'Archipel, puis un par arc et tous les étages-boss).
2. **Étages composés** (environ 55) : assemblés à partir de briques : un *Régime* (module de clauses), une *Société* (archétypes de personnages et de factions, avec 3 à 5 figures écrites à la main et le reste généré), un *Territoire* (famille d'espaces : labyrinthe, vertical, marais, désert, cité, grotte...) et un *Sceau* (grammaire de verrous). Un générateur compose, un solveur valide.
3. **Refuges** (environ 20) : des étages de répit, un tous les cinq étages : marché, société stable, mémoire de vos actes. C'est là que les Marques sont lues et qu'on peut changer de route.

**Grammaire des sceaux.** Les six types de verrous (consentement, mérite, moment, regard, état, offrande) se combinent. La difficulté croît par le *nombre de verrous couplés* et par la *distance entre l'indice et la solution*, jamais par la force des monstres.

**Courbe de complexité.** Étages 1 à 10 : un système nouveau par étage. Étages 11 à 30 : on couple deux systèmes. Étages 31 à 60 : trois systèmes couplés et des sociétés à factions. Étages 61 à 100 : des inversions (clauses qui se contredisent, lois à lire à la lettre, sceaux qui changent selon vos Marques).

**Technique (pour que 100 étages tiennent).** Un seul étage actif en mémoire, les autres sont des états sauvegardés. L'animation d'ascension masque le chargement. La société des étages inactifs tourne à pas lent (simulation de bas niveau) pour que la Tour continue de vivre. Sauvegarde par étage. Une graine par étage pour tout contenu généré, afin qu'un rechargement redonne exactement le même monde.

**Les Marques à l'échelle.** Elles ne s'accumulent pas indéfiniment : chaque arc les « lit » et les transforme au Refuge, pour que cent étages ne produisent pas cent conséquences ingérables.

**Garde-fous d'échelle.** Un solveur automatique valide chaque étage composé ; une règle « jamais deux étages consécutifs avec le même couple régime/sceau » ; un budget de contenu écrit à la main par arc.

**Idée directrice.** La Tour est un registre à cent chapitres : la cosmologie de la Clause (section 3) rend l'ensemble cohérent. Sceaux, lois et sociétés sont écrits dans la même langue, et plus le héros monte, mieux il la lit.

## 15. Courbe de complexité

| Étage | Systèmes nouveaux | Verrous / routes | Espace | Durée estimée |
| --- | --- | --- | --- | --- |
| 1 Seuil | horloge, réputation, écologie, Sceau, labyrinthe de haies | 3 / 2 | 260 × 260 | 2 à 3 h |
| 2 Asile | folie, graphe de pièces, plans fiables ou faux, 3 niveaux | 4 / 3 | 320 × 320 × 3 | 3 à 4 h |
| 3 Canopée | verticalité, factions, lettre contre esprit | 4 / 3 | 5 strates | 2 à 3 h |
| 4 Champ | guerre simulée, infiltration | 3 / 3 | très étendu | 3 à 4 h |
| 5 Archipel | navigation, mutinerie, boss | 3 / 3 | océan | 2 à 3 h |

MVP complet estimé : 12 à 17 heures.

## 16. Mémoire de la Tour (Marques)

| Marque | Origine | Effet |
| --- | --- | --- |
| Reconnu | route Honneur de l'étage 1 | accueil chaleureux, confiance de départ plus haute |
| Intrus | route Ruse | sentinelles plus attentives, chaos en hausse |
| Fou | Porte des Oubliés | hallucinations permanentes |
| Sang | Gourou, Reine, Capitaine tués par la force | cauchemars, factions hostiles |
| Parjure | route du Culte, pacte brisé | des clans ferment leurs portes |

## 17. Feuille de route technique

**Tranche A — l'étage 1 refondu, de bout en bout** (elle valide toute la méthode) : géographie close (faux ciel conservé, montagnes et Bout du monde à la place des murs, plus d'escalier visible : Chambre du Sceau sous la maison de l'Ancien avec animation d'ascension), système de Sceau et de verrous (remplace les conditions de victoire visibles), retour par glyphes et niveaux d'aide, journal sans objectifs et Carnet, requêtes et rites dans la société, générateur de labyrinthe (graine, repères, craie, serpe), Dédale peuplé, Puits à marée, Lanterne d'écho (prototype : rejouer la chronique de la société), tests d'invariants (solveur, absence de perte définitive, double source).

**Tranche B — l'Asile** : prototype non euclidien d'abord (portails continus, couloirs qui se replient), puis générateur de graphe de pièces et couloirs en boucle, trois niveaux, documents de plan, lumière et lanterne, déformation par la folie, Envers ; Culte en attente (interrupteur de fonctionnalité).

**Tranche C — la Canopée** : verticalité, factions, lettre de la clause.

**Tranche D — le Champ de bataille** : simulation de front.

**Tranche E — l'Archipel et le boss.**

## 18. Décisions à trancher

1. **Tranché : retours visuels du Sceau.** Des glyphes qui s'allument, avec un style soigné mais sobre pour ne pas surcharger le travail.
2. **Usage de la relique** (à choisir) : (a) la Lanterne d'écho, qui rejoue le passé récent des lieux (proposition actuelle) ; (b) un instrument de navigation du Dédale, qui montre les traces de ceux qui s'y sont perdus ; (c) une arme contre la Bête des Haies.
3. **Tranché : étages agrandis** (260 × 260 jouables). Les graphismes restent une preuve de concept et le budget de performance est relevé.
4. **Tranché : Asile non euclidien** avec effets poussés ; prototype des portails et des couloirs qui se replient avant tout autre contenu.
5. **Tranché : la Porte des Oubliés est cachée.** Elle apparaît à un endroit prévisible du labyrinthe si le héros porte un objet précis, et personne n'y entre sans l'avoir décidé. *Reste à définir* : quel est cet objet, et le coût de la traversée (une relation qui s'efface, une Marque perdue, ou une zone redevenue inconnue).
6. **Tranché : route du Culte conservée**, avec des avantages (protection, caveau du Gourou, immunité aux chants) et mise en attente propre par interrupteur de fonctionnalité si le temps manque.
7. **Tranché : tranche A d'abord.**
8. **Tranché : statistiques formées par les actes**, non prédéterminées, avec déblocages cachés (section 13). *Reste à valider* : la liste de départ (Vigueur, Agilité, Acuité, Sang-froid).
9. **Étage 1 sans verrou « Moment »** : on garde deux verrous (Consentement, Mérite), ou on introduit une autre contrainte de temps pour la route Honneur ?
10. **Tranché : l'Axe.** Tous les lieux d'ascension sont superposés sur un même axe vertical (section 4). *À confirmer* : c'est bien ce que vous entendiez par « toujours superposés ».
11. **100 étages** (section 14) : arcs de dix, étages-repères, composés et Refuges. *À valider* : la répartition et le contenu des étages 6 à 10.
