<div align="center">
  <h1>DRK Godot - Action Platformer 2D</h1>
  <p><em>Un jeu de plateforme et d'action 2D dynamique, nerveux et exigeant, developpe avec le moteur Godot 4.</em></p>
</div>

---

## 1. A propos du projet

Bienvenue dans le depot de **DRK Godot**. Ce projet est un prototype avance de jeu d'action-plateforme 2D qui met l'accent sur la fluidite des mouvements et un systeme de combat riche. Il s'inspire de grands classiques du genre Metroidvania et Souls-like en 2D pour proposer une experience de jeu technique ou le timing et la position sont cruciaux.

Le jeu propose un controleur de personnage complet, un systeme de combat base sur l'esquive et la parade, ainsi qu'une intelligence artificielle d'ennemis structuree autour d'une machine a etats finis.

## 2. Fonctionnalites Cles et Mecaniques de Jeu

### Le Joueur (Mouvements et Combat)
Le controleur du joueur (`player.gd`) a ete concu pour offrir un "Game Feel" reactif et precis. L'architecture permet de gerer de maniere fluide un grand nombre d'etats simultanes.

- **Deplacements au sol et esquives** : Le personnage peut marcher, courir, et sprinter pour ajuster son rythme. Pour la defense, le joueur dispose de roulades (offrant un deplacement court et securise) et d'un "dash" rapide au sol pour eviter les degats et se repositionner instantanement.
- **Deplacements aeriens** : Gestion avancee des sauts avec un "coyote time" (permettant de sauter une fraction de seconde apres avoir quitte une plateforme) et un "jump buffer" (enregistrant la commande de saut avant de toucher le sol). Le systeme inclut egalement la gestion des murs (sauts muraux et glissades le long des parois).
- **Pouvoir de teleportation** : Une competence de teleportation avec animation specifique (passage temporel en etat invisible) permettant de surprendre les ennemis ou de fuir une situation perilleuse en un eclair.
- **Systeme de combo et attaques** : Le combat au sol repose sur un enchainement progressif (Slash 1, Slash 2, pour finir par un puissant Spin Attack de zone). Le joueur peut egalement attaquer depuis les airs (Slam Attack, Fall Attack) ou declencher un coup imparable en fin de roulade (Roll Attack).
- **Parade Parfaite (Perfect Parry)** : Un systeme de garde est mis en place. Si la touche de parade est enfoncee juste avant de subir des degats, une "Parade Parfaite" est declenchee. Elle fige temporairement le temps (effet de Hitstop) et etourdit l'adversaire (Stun), offrant une ouverture pour contre-attaquer.

### L'Intelligence Artificielle (Les Ennemis)
L'IA (`ennemi.gd`) repose sur une machine a etats finis gerant rigoureusement le comportement et les cycles d'action des adversaires.

- **Etats principaux** : Attente (IDLE), Patrouille (PATROL), Traque (CHASE), Attaque (ATTACK), Blesse (HURT), Mort (DEATH) et Etourdi (STUNNED).
- **Cycle de vie de Base** : Les ennemis patrouillent passivement. S'ils detectent le vide ou un mur via un rayon (RayCast2D), ils font demi-tour intelligemment. Si le joueur entre dans leur zone de vision, ils se mettent en etat de Traque et forcent le contact. A portee, l'IA verrouille sa course pour declencher son animation d'attaque.
- **Impacts et Etourdissements** : Lorsqu'ils subissent des degats, les ennemis sont projetes en arriere (Knockback), reprennent temporairement leurs esprits et subissent un flash lumineux de degat. Un etourdissement via parade parfaite suspend temporairement leur logique interne pour le plus grand plaisir du joueur.

---

## 3. Architecture et Arborescence des Scenes

Le projet est structure de maniere modulaire en utilisant de facon optimale les systemes de Scene Tree de Godot. Voici un detail representatif de l'organisation des noeuds pour les elements cles :

### Le Joueur (`Player`)
La scene principale du joueur centralise la decouverte de la physique, la detection du sol, l'eclairage et les attaques.
- **Player** (CharacterBody2D) : Gère la physique et l'intégration du character controller.
  - **CollisionShape2D** : La hitbox physique de deplacement.
  - **Ancien_skin** / **Past_player** : Anciens assets visuels conserves.
  - **Camera2D** : La camera qui suit le deplacement du joueur dans le niveau.
  - **AnimationPlayer** : Orchestration et timing de toutes les animations du personnage (Marche, Attaques, Hit, Actions complexes).
  - **PointLight2D** (plusieurs) : Lumieres dynamiques centrees sur le joueur pour projeter ombres et volumes.
  - **Pivot** (Node2D) : Conteneur global qui s'inverse (scale de -1 a 1) en fonction de la direction de deplacement pour ne pas affecter la physique generale.
    - **Sprite2D** : Visuel principal actuel du joueur.
    - **Hitbox_Epee** (Area2D) : Zone attachee au joueur generant des degats sur sa trajectoire d'animation.
      - **CollisionShape2D**
    - **Particules_Pas** (GPUParticles2D) : Declenchement d'un nuage de poussieres lorsque le personnage touche le sol ou sprinte.

### L'Ennemi de Melee (`Ennemi`)
Scenario typique d'un ennemi au corps a corps, equipe de detecteurs sensoriels Godot natifs.
- **Ennemi** (CharacterBody2D)
  - **CollisionShape2D** : Collision d'environnement de base.
  - **AnimationPlayer** : Timing d'etats de patrouilles, d'attaques et des degats.
  - **Pivot** (Node2D) : Assure que tous les instruments de detection se retournent lorsque l'ennemi fait demi-tour.
    - **Detecteur_Sol** (RayCast2D) : Perce le sol immediatement en avant pour detecter les escarpements/vides et empecher l'ennemi de tomber.
    - **Vision** (Area2D) : Cone de detection qui ecoute l'entree du joueur (CollisionShape2D interne) pour initier l'etat CHASE.
    - **Attack** (Area2D) : Box de contact pour administrer sa logique de degats sur le joueur durant l'etat ATTACK.
    - **Sprite2D**

### L'Archer (`Ennemi_Archer`)
Une variante modifiee ciblant l'attaque a distance, reutilisant la fondation de l'ennemi basique.
- **Ennemi_Archer** (CharacterBody2D)
  - _(Meme structure de base que l'Ennemi ; Collision, AnimationPlayer)_
  - **Pivot** (Node2D)
    - _(RayCast sol, Areas Vision et Attack incluses)_
    - **Rayon** (Node2D) : Un assemblage modulaire propre a la portee pour cibler ou emettre de multiples visuels ou signaux en amont.
      - **Sprite_Rayon 1..3** (Sprite2D) : Segments composant un indicateur de tir a longue portee ou un deplacement type rayon.
    - **Flash** (Area2D / Node specifique) : Element visuel de decochement d'une fleche ou d'explosion a l'impact via sa hitbox interne (CollisionShape2D).

### Le Niveau Principal (Ex. `Node2D` / Main Scene)
C'est la scene principale ou le joueur evolue.
- **Node2D**
  - **TileMap** : Creation semi-automatique du terrain (Level Design). Les murs et le sol incluent directement des hitboxes physiques (via le Tileset).
  - **ParallaxBackground** : Background dynamique du jeu. Constitue de differents plans defilants (ParallaxLayer) echelles a des frequences differentes pour emuler la profondeur par un procede 2D de couches de Sprite2D / AnimatedSprite2D.
  - *Instances Acteurs* : **Player**, **Ennemi**, **Ennemi_Archer** y sont disposes a leur position initiale point de spawn.
  - **Canvases Generaux** : Modulate (CanvasModulate) pour definir des tons froids sur la globalite de la scene.
  - **Lumières** : Plusieurs `PointLight2D` eparpilles dans le niveau pour colorer certains decors sans detruire le Shader natif.
  - **ColorRect** / **WorldEnvironment** : Filtres et configuration Color Grading ou effets predefinis (Glow, Tonemapping) englobant tout l'ecran.

---

## 4. Controles (Clavier)

| Action | Touche(s) | Role et Details |
| :--- | :--- | :--- |
| **Se deplacer** | Flèches Gauche/Droite | Deplacement horizontal de base du CharacterBody. |
| **S'accroupir** | Flèche Bas | Permet de s'abaisser. |
| **Sauter** | Flèche Haut | Impulsion vericale (jump, wall jump, wall hold). |
| **Marche precise** | P | Mouvement maitrise (divise la vitesse par un facteur pour des plateformes fines). |
| **Sprint** | M (ou Maj) | Deplacement horizontal maximal sur la X-velocity. |
| **Attaque** | Espace | Declenche ou poursuit un composant de combo de la variable statique. |
| **Parade** | Block (Input customisé) | Guard simple ou trigger de fonction Parade si coordonnee. |
| **Roulade** | Roll (Input customisé) | Deplacement d'esquive avec un override temporaire des box de contact. |
| **Dash** | Dash (Input customisé) | Propension rapide sur une distance courte avant une pause forcée d'animations. |
| **Teleportation**| Teleport | Lancement de l'animation d'invisibilite instantanée pour reapparaitre a proximite apres verification des collisions. |

---

## 5. Details Techniques

- **Moteur :** Godot Engine 4.x (Fonctionne sous renderer natif GL Compatibility / Forward Plus).
- **Langage Base :** Implementations logiques en GDScript.
- **Physique :** Le module physique *Jolt Physics* a ete installe sur ce projet, ameliorant de maniere drastique la rapidite et la reactivite des checks de collider, annulant certains floats fantomes de la version native.
- **Gestion des evenements virtuels :** Utilisation etendue des "Await" en relation a l'`AnimationPlayer` de Godot (ex: le script attend que `Slam_Attack` se termine pour reset sa variable `is_attacking = false`). Il permet d'eluder efficacement une surcouche de timers.

### Demarrer le projet
1. Installer Godot Engine 4.x
2. Activer le plugin *Jolt Physics* en cas d'alerte lors de l'ouverture du projet (via un telechargement dans l'onglet Plugin/AssetLibrary).
3. Ouvrir ce dossier `yes-main` via l'interface Importation d'un Projet dans Godot depuis le `project.godot`.
4. Selectionner la Scene predefinie et executer la partie via Play (F5).
