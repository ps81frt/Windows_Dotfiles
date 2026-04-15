# 🖥️ Vim Windows — Guide d'utilisation

> Config basée sur `_vimrc` + `vim-plug` pour Windows.  
> **Leader key = `ESPACE`** (la touche espace remplace le préfixe de commande)

---

## 📦 Installation rapide

1. Place `_vimrc` et `install_vim_plugins.ps1` dans le **même dossier**
2. Ouvre PowerShell **en administrateur** dans ce dossier
3. Lance :
   ```powershell
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser   # si besoin, une seule fois
   .\install_vim_plugins.ps1
   ```
4. Le script installe vim-plug, copie le `_vimrc` et lance `PlugInstall` automatiquement.

### Dépendances externes (le script les détecte)

| Outil | Rôle | Commande winget |
|-------|------|-----------------|
| **git** | Télécharger les plugins | `winget install Git.Git` |
| **node/npm** | LSP TypeScript/HTML/CSS | `winget install OpenJS.NodeJS` |
| **python** | LSP Python (pyright) | `winget install Python.Python.3` |
| **dotnet** | OmniSharp C#/XAML | `winget install Microsoft.DotNet.SDK.8` |
| **ctags** | Tagbar (liste fonctions) | `winget install UniversalCtags.Ctags` |

> Après avoir installé les dépendances manquantes, ouvre un fichier du bon type dans Vim et lance `:LspInstallServer`

---

## 🗺️ Les panneaux / l'interface

Ta config ouvre plusieurs **panneaux** (fenêtres) autour de ton fichier. Voici comment t'y retrouver :

```
┌─────────────┬──────────────────────────┬──────────────┐
│  NERDTree   │                          │   Tagbar     │
│  (F3)       │     Ton fichier          │   (F8)       │
│  Explorateur│                          │  Fonctions/  │
│  de fichiers│                          │  Classes     │
└─────────────┴──────────────────────────┴──────────────┘
│ [buffer1] [buffer2] [buffer3]  ← onglets en haut (airline) │
│ Mode: NORMAL │ branche git │ ligne:col   ← barre en bas    │
```

### Naviguer entre les panneaux

| Raccourci | Action |
|-----------|--------|
| `Ctrl+h` | Aller au panneau **gauche** (NERDTree) |
| `Ctrl+l` | Aller au panneau **droite** (Tagbar) |
| `Ctrl+j` | Aller au panneau **bas** |
| `Ctrl+k` | Aller au panneau **haut** |

> **Astuce** : appuie sur `Ctrl+l` depuis NERDTree pour revenir dans ton fichier, `Ctrl+h` depuis ton fichier pour aller dans NERDTree.

---

## ⌨️ Touches de fonction (F1–F8)

| Touche | Action |
|--------|--------|
| **F1** | 📋 Ouvre le **menu interactif** (vim-quickui) — le plus simple pour débuter ! |
| **F2** | Bascule le mode **paste** (coller du texte sans décalage) |
| **F3** | 📁 Ouvre/ferme **NERDTree** (explorateur de fichiers à gauche) |
| **F4** | ❌ Efface la **surbrillance** de la dernière recherche |
| **F5** | 🔍 Ouvre **Clap** (recherche fuzzy ultra-rapide de fichiers) |
| **F8** | 🏷️ Ouvre/ferme **Tagbar** (liste des fonctions/classes du fichier) |

---

## 🧭 Navigation dans les fichiers (buffers/onglets)

Les "onglets" en haut de l'écran sont en réalité des **buffers**. La barre airline les affiche automatiquement.

| Raccourci | Action |
|-----------|--------|
| `ESPACE + n` | Buffer **suivant** (onglet suivant →) |
| `ESPACE + p` | Buffer **précédent** (onglet précédent ←) |
| `ESPACE + d` | **Fermer** le buffer courant |
| `Ctrl+p` | Rechercher et ouvrir un fichier (CtrlP fuzzy finder) |
| **F5** | Rechercher un fichier avec Clap (alternative moderne) |

> **Ouvrir un fichier depuis NERDTree** : navigue avec `j`/`k`, appuie sur `Entrée` pour ouvrir.

---

## 💾 Sauvegarder / Quitter

| Raccourci | Action |
|-----------|--------|
| `ESPACE + w` | **Sauvegarder** le fichier courant |
| `ESPACE + q` | **Quitter** la fenêtre courante |
| `:w` | Sauvegarder (mode commande classique) |
| `:wa` | Sauvegarder **tous** les fichiers ouverts |
| `:q` | Quitter |
| `:qa` | Quitter **tout** (ferme Vim) |
| `:wqa` | Sauvegarder tout et quitter |
| `:q!` | Quitter **sans sauvegarder** (force) |

---

## 🔤 Complétion automatique (LSP + asyncomplete)

Quand tu tapes du code, une liste de suggestions apparaît automatiquement.

| Touche | Action |
|--------|--------|
| `Tab` | Sélectionner la suggestion **suivante** ↓ |
| `Shift+Tab` | Sélectionner la suggestion **précédente** ↑ |
| `Entrée` | **Valider** la suggestion choisie |
| `Échap` | **Fermer** la liste de suggestions |

> La complétion s'active selon le serveur LSP détecté pour ton type de fichier.

---

## 🔎 LSP — Fonctions intelligentes

Le LSP (Language Server Protocol) apporte de l'intelligence à l'éditeur (aller à la définition, renommage, etc.)

| Raccourci | Action |
|-----------|--------|
| `gd` | **Aller à la définition** de la fonction/variable sous le curseur |
| `gr` | Voir toutes les **références** (où c'est utilisé) |
| `K` | **Afficher la doc** / info au survol (hover) |
| `ESPACE + rn` | **Renommer** la variable/fonction partout dans le projet |
| `ESPACE + f` | **Formater** le document (indentation, style) |
| `ESPACE + e` | **Voir les erreurs** du fichier (diagnostics) |

### Installer un serveur LSP

Ouvre un fichier du bon type (`.py`, `.cs`, `.ts`...) puis tape :
```
:LspInstallServer
```
Vim télécharge et configure automatiquement le bon serveur.

---

## ✏️ Édition rapide

### Commenter / décommenter

| Raccourci | Action |
|-----------|--------|
| `gcc` | Commenter/décommenter la **ligne courante** |
| `gc` + mouvement | Commenter une **sélection** (ex: `gc3j` = 3 lignes vers le bas) |

### Entourer du texte (vim-surround)

| Raccourci | Action |
|-----------|--------|
| `cs"'` | Changer `"texte"` en `'texte'` |
| `cs'<p>` | Changer `'texte'` en `<p>texte</p>` |
| `ds"` | Supprimer les guillemets autour du mot |
| `ysiw"` | Entourer le mot sous le curseur avec `"` |

### HTML / XML / XAML

| Raccourci | Action |
|-----------|--------|
| `Ctrl+e ,` | **Emmet** : expande un raccourci HTML (ex: `div.container` → balise complète) |
| Fermeture auto | Les balises `</...>` se ferment seules en tapant `</` |

---

## 🔍 Recherche dans les fichiers

| Raccourci | Action |
|-----------|--------|
| `/texte` | Rechercher `texte` dans le fichier |
| `n` | Occurrence **suivante** |
| `N` | Occurrence **précédente** |
| **F4** | **Effacer** la surbrillance |
| `Ctrl+p` | **CtrlP** : recherche floue dans tous les fichiers du projet |
| **F5** | **Clap** : recherche floue avec aperçu en temps réel |

---

## 🌿 Git (vim-gitgutter)

Des symboles apparaissent dans la marge gauche pour indiquer les modifications git.

| Symbole | Signification |
|---------|--------------|
| `+` | Ligne ajoutée |
| `~` | Ligne modifiée |
| `-` | Ligne supprimée |

| Raccourci | Action |
|-----------|--------|
| `]c` | Aller au **prochain** changement |
| `[c` | Aller au **précédent** changement |
| Menu F1 → Git | Stage / Undo / Preview un hunk |

---

## 📋 Menu interactif — F1

Appuie sur **F1** pour ouvrir le menu déroulant. Navigue avec les flèches, valide avec `Entrée`.

```
[File]  [Edit]  [LSP]  [Git]  [View]
```

| Menu | Contenu |
|------|---------|
| **File** | NERDTree, CtrlP, Sauvegarder, Quitter |
| **Edit** | Commenter, Rechercher, Clap |
| **LSP** | Définition, Hover, Références, Renommer, Formater, Diagnostics |
| **Git** | Navigation et actions sur les hunks git |
| **View** | Tagbar, Indent guides, Cursorline, Effacer surbrillance |

> C'est le point d'entrée idéal si tu ne te souviens plus d'un raccourci !

---

## ⚡ Résumé express — Les essentiels

```
F1          → Menu (tout est dedans)
F3          → Explorateur de fichiers
F5          → Chercher un fichier
F8          → Liste des fonctions

ESPACE+w    → Sauvegarder
ESPACE+q    → Quitter
ESPACE+n/p  → Changer d'onglet (buffer)

Ctrl+h/l    → Changer de panneau (gauche/droite)

gd          → Aller à la définition
K           → Documentation rapide
gcc         → Commenter la ligne

Tab/Entrée  → Valider la complétion
```

---

## 🐛 Problèmes fréquents

| Problème | Solution |
|----------|----------|
| La complétion ne fonctionne pas | Lance `:LspInstallServer` avec le bon fichier ouvert |
| NERDTree ne s'ouvre pas | Appuie sur `F3` depuis le mode NORMAL (pas INSERT) |
| Les couleurs sont moches | Ajoute une Nerd Font et mets `let g:airline_powerline_fonts = 1` dans `_vimrc` |
| `gd` ne trouve pas la définition | Le serveur LSP n'est pas encore démarré — attends quelques secondes ou vérifie `:LspStatus` |
| Tagbar vide | Installe `ctags` : `winget install UniversalCtags.Ctags` |
| Coller du texte fait des décalages | Appuie sur `F2` avant de coller, puis `F2` après |

---

*Config Vim pour Windows — vim-plug + LSP + NERDTree + airline*
