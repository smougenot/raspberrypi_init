#!/bin/bash

#
# Script de nettoyage de l'environnement Ansible
# Supprime l'environnement pipenv et optionnellement pyenv
#

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Nettoyage environnement Ansible ===${NC}"

# Fonction pour vérifier si une commande existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Supprimer l'environnement pipenv
if command_exists pipenv && [ -f "Pipfile" ]; then
    echo -e "${YELLOW}Suppression de l'environnement pipenv...${NC}"
    pipenv --rm 2>/dev/null || true
    echo -e "${GREEN}✓ Environnement pipenv supprimé${NC}"
fi

# Supprimer les fichiers de lock
if [ -f "Pipfile.lock" ]; then
    echo -e "${YELLOW}Suppression du Pipfile.lock...${NC}"
    rm -f Pipfile.lock
    echo -e "${GREEN}✓ Pipfile.lock supprimé${NC}"
fi

# Proposer de supprimer pyenv (optionnel)
if command_exists pyenv; then
    echo ""
    echo -e "${YELLOW}pyenv est installé. Options:${NC}"
    echo "1. Garder pyenv (recommandé)"
    echo "2. Supprimer seulement Python 3.11.9"
    echo "3. Supprimer complètement pyenv"
    echo ""
    read -p "Choisissez une option (1-3) [défaut: 1]: " choice
    
    case ${choice:-1} in
        2)
            echo -e "${YELLOW}Suppression de Python 3.11.9...${NC}"
            pyenv uninstall -f 3.11.9 2>/dev/null || true
            echo -e "${GREEN}✓ Python 3.11.9 supprimé${NC}"
            ;;
        3)
            echo -e "${YELLOW}Suppression complète de pyenv...${NC}"
            rm -rf ~/.pyenv
            
            # Nettoyer les configurations de shell
            for rc in ~/.bashrc ~/.zshrc ~/.profile; do
                if [ -f "$rc" ]; then
                    sed -i '/# pyenv configuration/,+3d' "$rc" 2>/dev/null || true
                    sed -i '/export PATH.*pyenv/d' "$rc" 2>/dev/null || true
                    sed -i '/eval.*pyenv/d' "$rc" 2>/dev/null || true
                fi
            done
            
            echo -e "${GREEN}✓ pyenv complètement supprimé${NC}"
            echo -e "${YELLOW}Redémarrez votre shell pour que les changements prennent effet${NC}"
            ;;
        *)
            echo -e "${GREEN}✓ pyenv conservé${NC}"
            ;;
    esac
fi

# Supprimer le fichier .python-version local
if [ -f ".python-version" ]; then
    echo ""
    read -p "Supprimer le fichier .python-version local ? (y/N): " remove_version
    if [[ "$remove_version" =~ ^[Yy]$ ]]; then
        rm -f .python-version
        echo -e "${GREEN}✓ .python-version supprimé${NC}"
    fi
fi

echo ""
echo -e "${GREEN}=== Nettoyage terminé ===${NC}"
echo -e "${YELLOW}Pour reconfigurer l'environnement:${NC}"
echo "  ./setup_pyenv_pipenv.sh    # Installation complète avec pyenv"
echo "  ./setup_ansible_env.sh     # Installation standard"
