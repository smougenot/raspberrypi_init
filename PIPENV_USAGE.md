# Installation et Utilisation d'Ansible avec pipenv

## Approches d'installation

### 🎯 **Recommandée: pyenv + pipenv (sans impact système)**
```bash
./setup_pyenv_pipenv.sh
```
Cette approche :
- ✅ N'installe rien au niveau système (pas de `sudo dnf install`)
- ✅ Gère automatiquement la version Python via pyenv
- ✅ Crée un environnement isolé avec pipenv
- ✅ Fonctionne sur tous les systèmes Unix/Linux/macOS

### 📦 **Classique: Installation système**
```bash
./setup_ansible_env.sh
```

### 🔧 **Spécifique Fedora avec pyenv**
```bash
./setup_fedora.sh
```

## Systèmes supportés

Le script d'installation automatique supporte les distributions suivantes :

- **Debian/Ubuntu/Raspbian** : Installation via `apt-get`
- **Fedora** : Installation via `dnf`
- **CentOS/RHEL/Rocky/AlmaLinux** : Installation via `dnf` ou `yum`
- **Arch Linux/Manjaro** : Installation via `pacman`
- **openSUSE** : Installation via `zypper`
- **macOS** : Installation via `brew`

## Installation automatique

Le projet configure automatiquement Ansible avec pipenv lors de la première utilisation.

### Méthode 1: Script principal (recommandé)
```bash
./raspian_first_boot.sh
```
Le script vérifiera et installera automatiquement l'environnement Ansible si nécessaire.

### Méthode 2: Installation manuelle
```bash
./setup_ansible_env.sh
```

### Méthode 2b: Installation spécifique Fedora (recommandé sur Fedora)
```bash
./setup_fedora.sh
```
Ce script installe automatiquement Python 3.9+ si nécessaire sur Fedora.

### Méthode 3: Script d'aide
```bash
./ansible.sh help
```

### Méthode 4: Test de l'installation
```bash
./test_ansible_env.sh
```
Ce script vérifie que tous les composants sont correctement installés.

## Gestion des versions Python avec pyenv

Le projet utilise un fichier `.python-version` qui spécifie la version Python recommandée (3.11.9).

### Avantages de pyenv + pipenv
- **Isolation complète** : Aucun impact sur le Python système
- **Gestion des versions** : Facilite le passage entre différentes versions
- **Reproductibilité** : Même environnement sur toutes les machines
- **Pas de sudo requis** : Installation dans le répertoire utilisateur uniquement

### Commandes pyenv utiles
```bash
pyenv versions              # Lister les versions installées
pyenv global 3.11.9         # Définir version globale
pyenv local 3.11.9          # Définir version pour le projet courant
pyenv which python          # Voir quel Python est utilisé
```

## Utilisation

### Commandes courantes
```bash
# Configuration d'un Pi
./ansible.sh playbook raspian_first_boot.yml

# Test de connectivité
./ansible.sh ping

# Vérification de la syntaxe
./ansible.sh lint *.yml

# Installation des rôles Galaxy
./ansible.sh galaxy-install
```

### Commandes pipenv directes
```bash
# Installer l'environnement
pipenv install

# Activer l'environnement
pipenv shell

# Exécuter une commande dans l'environnement
pipenv run ansible --version
pipenv run ansible-playbook mon-playbook.yml
```

## Structure des fichiers

- `Pipfile` - Définition des dépendances Python
- `setup_ansible_env.sh` - Script d'installation automatique
- `ansible.sh` - Script d'aide pour les commandes courantes
- `requirements.yml` - Rôles et collections Ansible Galaxy
- `raspian_first_boot.sh` - Script principal de configuration

## Avantages de pipenv

- ✅ Isolation de l'environnement Python
- ✅ Gestion automatique des dépendances
- ✅ Reproductibilité entre les machines
- ✅ Pas de conflit avec les packages système
- ✅ Installation et mise à jour simplifiées

## Dépannage

### Problème avec ansible-lint sur Python 3.8
Si vous obtenez des erreurs avec ansible-lint :
```bash
# Utiliser le script spécifique Fedora
./setup_fedora.sh

# Ou désinstaller ansible-lint
pipenv uninstall ansible-lint
```

### Problème de version Python
```bash
# Vérifier la version Python
python3 --version

# Sur Fedora, installer Python 3.11
sudo dnf install python3.11 python3.11-pip

# Recréer l'environnement
pipenv --rm
pipenv --python python3.11 install
```

### Vérifier l'installation
```bash
./test_ansible_env.sh
```
