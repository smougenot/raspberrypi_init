#!/bin/bash

#
# Script d'installation spécifique pour Fedora
# Installe Python 3.9+ si nécessaire
#

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Configuration Ansible pour Fedora ===${NC}"

# Vérifier si on est sur Fedora
if [ ! -f /etc/fedora-release ]; then
    echo -e "${RED}Ce script est conçu pour Fedora uniquement${NC}"
    exit 1
fi

FEDORA_VERSION=$(cat /etc/fedora-release | grep -o '[0-9]\+' | head -1)
echo -e "${GREEN}Fedora version détectée: ${FEDORA_VERSION}${NC}"

# Installer Python 3.9+ si pas disponible
if ! python3.9 --version >/dev/null 2>&1 && ! python3.10 --version >/dev/null 2>&1 && ! python3.11 --version >/dev/null 2>&1; then
    echo -e "${YELLOW}Installation de Python 3.11...${NC}"
    sudo dnf install -y python3.11 python3.11-pip python3.11-devel
    
    # Créer un lien symbolique pour faciliter l'utilisation
    if [ ! -f /usr/local/bin/python3-ansible ]; then
        sudo ln -s /usr/bin/python3.11 /usr/local/bin/python3-ansible
    fi
    
    PYTHON_CMD="python3-ansible"
else
    # Utiliser la version disponible
    for version in 3.11 3.10 3.9; do
        if python${version} --version >/dev/null 2>&1; then
            PYTHON_CMD="python${version}"
            break
        fi
    done
fi

echo -e "${GREEN}Utilisation de: $(${PYTHON_CMD} --version)${NC}"

# Installer pipenv avec la bonne version de Python
echo -e "${YELLOW}Installation de pipenv...${NC}"
${PYTHON_CMD} -m pip install --user pipenv

# Ajouter au PATH
export PATH="$HOME/.local/bin:$PATH"
if [ -f ~/.bashrc ]; then
    grep -q 'PATH.*\.local/bin' ~/.bashrc || echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
fi

# Configurer pipenv pour utiliser la bonne version de Python
export PIPENV_PYTHON=${PYTHON_CMD}

# Créer l'environnement avec la bonne version
echo -e "${YELLOW}Configuration de l'environnement Ansible...${NC}"
pipenv --python ${PYTHON_CMD} install

echo -e "${GREEN}=== Configuration terminée ===${NC}"
echo -e "${GREEN}Environnement Ansible configuré avec $(${PYTHON_CMD} --version)${NC}"
echo ""
echo -e "${YELLOW}Pour utiliser l'environnement:${NC}"
echo "  pipenv shell"
echo "  pipenv run ansible --version"
