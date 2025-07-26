#!/bin/bash

#
# Script d'installation Ansible avec pyenv + pipenv
# Fonctionne sur tous les systèmes Unix sans modifier l'OS hôte
#

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Configuration Ansible avec pyenv + pipenv ===${NC}"

# Fonction pour vérifier si une commande existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Fonction pour détecter la distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo $ID
    elif [ -f /etc/redhat-release ]; then
        echo "rhel"
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    else
        uname -s | tr '[:upper:]' '[:lower:]'
    fi
}

# Version Python cible
TARGET_PYTHON_VERSION="3.11.1"  # Version stable disponible
DISTRO=$(detect_distro)

echo -e "${GREEN}Système détecté: ${DISTRO}${NC}"
echo -e "${GREEN}Version Python cible: ${TARGET_PYTHON_VERSION}${NC}"

# Installer les dépendances de compilation selon la distribution
install_build_dependencies() {
    echo -e "${YELLOW}Installation des dépendances de compilation...${NC}"
    
    case $DISTRO in
        "ubuntu"|"debian"|"raspbian")
            sudo apt-get update
            sudo apt-get install -y make build-essential libssl-dev zlib1g-dev \
                libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
                libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev \
                libffi-dev liblzma-dev git
            ;;
        "fedora")
            sudo dnf install -y make gcc zlib-devel bzip2 bzip2-devel \
                readline-devel sqlite sqlite-devel openssl-devel tk-devel \
                libffi-devel xz-devel git
            ;;
        "centos"|"rhel"|"rocky"|"almalinux")
            if command_exists dnf; then
                sudo dnf groupinstall -y "Development Tools"
                sudo dnf install -y zlib-devel bzip2 bzip2-devel readline-devel \
                    sqlite sqlite-devel openssl-devel tk-devel libffi-devel xz-devel git
            else
                sudo yum groupinstall -y "Development Tools"
                sudo yum install -y zlib-devel bzip2 bzip2-devel readline-devel \
                    sqlite sqlite-devel openssl-devel tk-devel libffi-devel xz-devel git
            fi
            ;;
        "arch"|"manjaro")
            sudo pacman -S --noconfirm base-devel openssl zlib xz tk git
            ;;
        "opensuse"|"opensuse-leap"|"opensuse-tumbleweed")
            sudo zypper install -y -t pattern devel_basis
            sudo zypper install -y zlib-devel bzip2 libbz2-devel readline-devel \
                sqlite3-devel openssl-devel tk-devel libffi-devel xz-devel git
            ;;
        "darwin")
            if command_exists brew; then
                brew install openssl readline sqlite3 xz zlib tcl-tk git
            else
                echo -e "${RED}Homebrew requis sur macOS. Installez-le depuis https://brew.sh${NC}"
                exit 1
            fi
            ;;
        *)
            echo -e "${YELLOW}Distribution inconnue. Assurez-vous d'avoir les outils de développement installés.${NC}"
            ;;
    esac
    
    echo -e "${GREEN}✓ Dépendances installées${NC}"
}

# Installer pyenv si pas présent
if ! command_exists pyenv; then
    echo -e "${YELLOW}Installation de pyenv...${NC}"
    
    # Installer les dépendances
    install_build_dependencies
    
    # Installer pyenv
    curl https://pyenv.run | bash
    
    # Ajouter pyenv au PATH et configuration
    export PATH="$HOME/.pyenv/bin:$PATH"
    
    # Configuration automatique des shells
    configure_shell() {
        local shell_rc=$1
        if [ -f "$shell_rc" ] && ! grep -q 'pyenv init' "$shell_rc"; then
            echo '' >> "$shell_rc"
            echo '# pyenv configuration' >> "$shell_rc"
            echo 'export PATH="$HOME/.pyenv/bin:$PATH"' >> "$shell_rc"
            echo 'eval "$(pyenv init --path)"' >> "$shell_rc"
            echo 'eval "$(pyenv init -)"' >> "$shell_rc"
            echo -e "${GREEN}✓ Configuration ajoutée à $(basename "$shell_rc")${NC}"
        fi
    }
    
    configure_shell ~/.bashrc
    configure_shell ~/.zshrc
    configure_shell ~/.profile
    
    # Initialiser pyenv pour cette session
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
    
    echo -e "${GREEN}✓ pyenv installé et configuré${NC}"
else
    echo -e "${GREEN}✓ pyenv déjà présent${NC}"
    
    # S'assurer que pyenv est initialisé
    export PATH="$HOME/.pyenv/bin:$PATH"
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
fi

# Vérifier et installer la version Python cible
if ! pyenv versions --bare | grep -q "^${TARGET_PYTHON_VERSION}$"; then
    echo -e "${YELLOW}Installation de Python ${TARGET_PYTHON_VERSION} via pyenv...${NC}"
    
    # Vérifier si la version est disponible, sinon mettre à jour pyenv
    if ! pyenv install --list | grep -q "^  ${TARGET_PYTHON_VERSION}$"; then
        echo -e "${YELLOW}Version non trouvée, mise à jour de pyenv...${NC}"
        cd ~/.pyenv && git pull && cd -
        
        # Vérifier à nouveau
        if ! pyenv install --list | grep -q "^  ${TARGET_PYTHON_VERSION}$"; then
            echo -e "${YELLOW}Version ${TARGET_PYTHON_VERSION} toujours non disponible.${NC}"
            echo -e "${YELLOW}Utilisation de la dernière version 3.11 disponible...${NC}"
            TARGET_PYTHON_VERSION=$(pyenv install --list | grep "^  3\.11\.[0-9]*$" | tail -1 | xargs)
            echo -e "${GREEN}Version sélectionnée: ${TARGET_PYTHON_VERSION}${NC}"
        fi
    fi
    
    echo -e "${YELLOW}Cela peut prendre plusieurs minutes...${NC}"
    pyenv install ${TARGET_PYTHON_VERSION}
    echo -e "${GREEN}✓ Python ${TARGET_PYTHON_VERSION} installé${NC}"
else
    echo -e "${GREEN}✓ Python ${TARGET_PYTHON_VERSION} déjà installé${NC}"
fi

# Définir la version Python locale pour ce projet
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
    
    # Configuration automatique des shells pour pipenv
    add_to_path() {
        local shell_rc=$1
        if [ -f "$shell_rc" ] && ! grep -q 'PATH.*\.local/bin' "$shell_rc"; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$shell_rc"
            echo -e "${GREEN}✓ PATH mis à jour dans $(basename "$shell_rc")${NC}"
        fi
    }
    
    add_to_path ~/.bashrc
    add_to_path ~/.zshrc
    add_to_path ~/.profile
    
    echo -e "${GREEN}✓ pipenv installé${NC}"
else
    echo -e "${GREEN}✓ pipenv déjà présent${NC}"
fi

# S'assurer que pipenv est dans le PATH
export PATH="$HOME/.local/bin:$PATH"

# Nettoyer l'environnement existant si nécessaire
if [ -f "Pipfile.lock" ]; then
    CURRENT_PYTHON=$(pipenv --py 2>/dev/null | xargs basename 2>/dev/null || echo "unknown")
    if [[ "$CURRENT_PYTHON" != *"${TARGET_PYTHON_VERSION}"* ]]; then
        echo -e "${YELLOW}Nettoyage de l'environnement existant (mauvaise version Python)...${NC}"
        pipenv --rm 2>/dev/null || true
        rm -f Pipfile.lock
    fi
fi

# Créer/Mettre à jour l'environnement
echo -e "${YELLOW}Configuration de l'environnement Ansible avec pipenv...${NC}"
pipenv install

# Vérification finale
echo -e "${YELLOW}Vérification de l'installation...${NC}"
if pipenv run python --version | grep -q "${TARGET_PYTHON_VERSION}"; then
    echo -e "${GREEN}✓ Environnement configuré correctement${NC}"
    pipenv run python --version
    pipenv run pip list | grep -E "(ansible|pipenv)"
else
    echo -e "${RED}✗ Problème de configuration détecté${NC}"
    exit 1
fi

echo -e "${GREEN}=== Configuration terminée avec succès ===${NC}"
echo -e "${GREEN}Environnement Ansible configuré avec Python ${TARGET_PYTHON_VERSION}${NC}"
echo -e "${GREEN}Géré par pyenv + pipenv (aucun impact sur le système hôte)${NC}"
echo ""
echo -e "${YELLOW}Commandes utiles:${NC}"
echo "  pipenv shell                    # Activer l'environnement"
echo "  pipenv run ansible --version    # Vérifier Ansible"
echo "  ./test_ansible_env.sh          # Tester l'installation"
echo "  pyenv versions                 # Voir les versions Python installées"
echo ""
echo -e "${YELLOW}Note:${NC} Redémarrez votre shell ou sourcez votre profil pour que pyenv soit disponible partout."
