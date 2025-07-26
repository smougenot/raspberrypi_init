#!/bin/bash

#
# Script d'installation spécifique pour Fedora
# Utilise pyenv + pipenv pour gérer Python sans modifier le système
#

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Configuration Ansible pour Fedora avec pyenv ===${NC}"

# Vérifier si on est sur Fedora
if [ ! -f /etc/fedora-release ]; then
    echo -e "${RED}Ce script est conçu pour Fedora uniquement${NC}"
    exit 1
fi

FEDORA_VERSION=$(cat /etc/fedora-release | grep -o '[0-9]\+' | head -1)
echo -e "${GREEN}Fedora version détectée: ${FEDORA_VERSION}${NC}"

# Fonction pour vérifier si une commande existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Version Python cible pour Ansible (compatible avec ansible-lint)
TARGET_PYTHON_VERSION="3.11.9"

# Installer pyenv si pas présent
if ! command_exists pyenv; then
    echo -e "${YELLOW}Installation de pyenv...${NC}"
    
    # Installer les dépendances de compilation sans toucher au Python système
    echo -e "${YELLOW}Installation des dépendances de compilation...${NC}"
    sudo dnf install -y make gcc zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel openssl-devel tk-devel libffi-devel xz-devel
    
    # Installer pyenv
    curl https://pyenv.run | bash
    
    # Ajouter pyenv au PATH et aux shells
    export PATH="$HOME/.pyenv/bin:$PATH"
    
    # Configuration pour bash
    if [ -f ~/.bashrc ]; then
        if ! grep -q 'pyenv init' ~/.bashrc; then
            echo '' >> ~/.bashrc
            echo '# pyenv configuration' >> ~/.bashrc
            echo 'export PATH="$HOME/.pyenv/bin:$PATH"' >> ~/.bashrc
            echo 'eval "$(pyenv init --path)"' >> ~/.bashrc
            echo 'eval "$(pyenv init -)"' >> ~/.bashrc
        fi
    fi
    
    # Configuration pour zsh si présent
    if [ -f ~/.zshrc ]; then
        if ! grep -q 'pyenv init' ~/.zshrc; then
            echo '' >> ~/.zshrc
            echo '# pyenv configuration' >> ~/.zshrc
            echo 'export PATH="$HOME/.pyenv/bin:$PATH"' >> ~/.zshrc
            echo 'eval "$(pyenv init --path)"' >> ~/.zshrc
            echo 'eval "$(pyenv init -)"' >> ~/.zshrc
        fi
    fi
    
    # Initialiser pyenv pour cette session
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
    
    echo -e "${GREEN}✓ pyenv installé${NC}"
else
    echo -e "${GREEN}✓ pyenv déjà présent${NC}"
    
    # S'assurer que pyenv est initialisé
    export PATH="$HOME/.pyenv/bin:$PATH"
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
fi

# Vérifier si la version Python cible est installée
if ! pyenv versions --bare | grep -q "^${TARGET_PYTHON_VERSION}$"; then
    echo -e "${YELLOW}Installation de Python ${TARGET_PYTHON_VERSION} via pyenv...${NC}"
    pyenv install ${TARGET_PYTHON_VERSION}
    echo -e "${GREEN}✓ Python ${TARGET_PYTHON_VERSION} installé${NC}"
else
    echo -e "${GREEN}✓ Python ${TARGET_PYTHON_VERSION} déjà installé${NC}"
fi

# Définir la version Python pour ce projet
echo -e "${YELLOW}Configuration de Python ${TARGET_PYTHON_VERSION} pour ce projet...${NC}"
pyenv local ${TARGET_PYTHON_VERSION}

# Vérifier la version active
ACTIVE_PYTHON_VERSION=$(python --version 2>&1)
echo -e "${GREEN}Version Python active: ${ACTIVE_PYTHON_VERSION}${NC}"

# Installer pipenv si pas présent
if ! command_exists pipenv; then
    echo -e "${YELLOW}Installation de pipenv...${NC}"
    python -m pip install --user pipenv
    
    # Ajouter pipenv au PATH
    export PATH="$HOME/.local/bin:$PATH"
    if [ -f ~/.bashrc ]; then
        grep -q 'PATH.*\.local/bin' ~/.bashrc || echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    fi
    if [ -f ~/.zshrc ]; then
        grep -q 'PATH.*\.local/bin' ~/.zshrc || echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
    fi
    
    echo -e "${GREEN}✓ pipenv installé${NC}"
else
    echo -e "${GREEN}✓ pipenv déjà présent${NC}"
fi

# S'assurer que pipenv est dans le PATH
export PATH="$HOME/.local/bin:$PATH"

# Supprimer l'environnement existant s'il existe et utilise une mauvaise version
if [ -f "Pipfile.lock" ]; then
    echo -e "${YELLOW}Nettoyage de l'environnement existant...${NC}"
    pipenv --rm 2>/dev/null || true
fi

# Créer l'environnement avec la version Python gérée par pyenv
echo -e "${YELLOW}Configuration de l'environnement Ansible avec pipenv...${NC}"
pipenv install

echo -e "${GREEN}=== Configuration terminée ===${NC}"
echo -e "${GREEN}Environnement Ansible configuré avec Python ${TARGET_PYTHON_VERSION}${NC}"
echo -e "${GREEN}Géré par pyenv (pas d'impact sur le système hôte)${NC}"
echo ""
echo -e "${YELLOW}Pour utiliser l'environnement:${NC}"
echo "  pipenv shell"
echo "  pipenv run ansible --version"
echo ""
echo -e "${YELLOW}Pour vérifier l'installation:${NC}"
echo "  ./test_ansible_env.sh"
