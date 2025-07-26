#!/bin/bash

#
# Ansible Environment Setup Script
# Vérifie et installe automatiquement Ansible avec pipenv
#

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Vérification de l'environnement Ansible ===${NC}"

# Fonction pour vérifier si une commande existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Fonction pour détecter la distribution Linux
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo $ID
    elif [ -f /etc/redhat-release ]; then
        echo "rhel"
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    else
        echo "unknown"
    fi
}

# Détecter et afficher le système
DISTRO=$(detect_distro)
echo -e "${GREEN}Système détecté: ${DISTRO}${NC}"

# Vérifier si pyenv est disponible et l'utiliser de préférence
if command_exists pyenv && [ -f ".python-version" ]; then
    echo -e "${GREEN}pyenv détecté avec fichier .python-version${NC}"
    TARGET_VERSION=$(cat .python-version)
    
    # Initialiser pyenv
    export PATH="$HOME/.pyenv/bin:$PATH"
    eval "$(pyenv init --path)" 2>/dev/null || true
    eval "$(pyenv init -)" 2>/dev/null || true
    
    if pyenv versions --bare | grep -q "^${TARGET_VERSION}$"; then
        echo -e "${GREEN}✓ Utilisation de Python ${TARGET_VERSION} via pyenv${NC}"
    else
        echo -e "${YELLOW}Version Python ${TARGET_VERSION} non installée via pyenv${NC}"
        echo -e "${YELLOW}Utilisez: ./setup_pyenv_pipenv.sh pour une installation complète${NC}"
    fi
fi

# Fonction pour installer pipenv
install_pipenv() {
    echo -e "${YELLOW}Installation de pipenv...${NC}"
    local distro=$(detect_distro)
    
    case $distro in
        "ubuntu"|"debian"|"raspbian")
            echo -e "${GREEN}Détection: Système basé sur Debian${NC}"
            sudo apt-get update
            sudo apt-get install -y python3 python3-pip python3-venv python3-dev build-essential
            python3 -m pip install --user pipenv
            ;;
        "fedora")
            echo -e "${GREEN}Détection: Fedora${NC}"
            sudo dnf install -y python3 python3-pip python3-devel gcc make
            python3 -m pip install --user pipenv
            ;;
        "centos"|"rhel"|"rocky"|"almalinux")
            echo -e "${GREEN}Détection: Système basé sur RHEL${NC}"
            if command_exists dnf; then
                sudo dnf install -y python3 python3-pip python3-devel gcc make
            else
                sudo yum install -y python3 python3-pip python3-devel gcc make
            fi
            python3 -m pip install --user pipenv
            ;;
        "arch"|"manjaro")
            echo -e "${GREEN}Détection: Système basé sur Arch${NC}"
            sudo pacman -S --noconfirm python python-pip base-devel
            python3 -m pip install --user pipenv
            ;;
        "opensuse"|"opensuse-leap"|"opensuse-tumbleweed")
            echo -e "${GREEN}Détection: openSUSE${NC}"
            sudo zypper install -y python3 python3-pip python3-devel gcc make
            python3 -m pip install --user pipenv
            ;;
        *)
            if command_exists brew; then
                echo -e "${GREEN}Détection: macOS${NC}"
                brew install pipenv
            elif command_exists apt-get; then
                echo -e "${YELLOW}Tentative avec apt-get...${NC}"
                sudo apt-get update
                sudo apt-get install -y python3 python3-pip python3-venv python3-dev build-essential
                python3 -m pip install --user pipenv
            elif command_exists dnf; then
                echo -e "${YELLOW}Tentative avec dnf...${NC}"
                sudo dnf install -y python3 python3-pip python3-devel gcc make
                python3 -m pip install --user pipenv
            elif command_exists yum; then
                echo -e "${YELLOW}Tentative avec yum...${NC}"
                sudo yum install -y python3 python3-pip python3-devel gcc make
                python3 -m pip install --user pipenv
            else
                echo -e "${RED}Système non supporté pour l'installation automatique${NC}"
                echo "Distribution détectée: $distro"
                echo "Veuillez installer pipenv manuellement:"
                echo "  python3 -m pip install --user pipenv"
                exit 1
            fi
            ;;
    esac
    
    # Ajouter pipenv au PATH
    export PATH="$HOME/.local/bin:$PATH"
    if [ -f ~/.bashrc ]; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    fi
    if [ -f ~/.zshrc ]; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
    fi
}

# Vérifier Python
if ! command_exists python3; then
    echo -e "${YELLOW}Python3 non trouvé, tentative d'installation...${NC}"
    local distro=$(detect_distro)
    
    case $distro in
        "ubuntu"|"debian"|"raspbian")
            sudo apt-get update
            sudo apt-get install -y python3 python3-pip python3-venv
            ;;
        "fedora")
            sudo dnf install -y python3 python3-pip
            ;;
        "centos"|"rhel"|"rocky"|"almalinux")
            if command_exists dnf; then
                sudo dnf install -y python3 python3-pip
            else
                sudo yum install -y python3 python3-pip
            fi
            ;;
        "arch"|"manjaro")
            sudo pacman -S --noconfirm python python-pip
            ;;
        "opensuse"|"opensuse-leap"|"opensuse-tumbleweed")
            sudo zypper install -y python3 python3-pip
            ;;
        *)
            echo -e "${RED}Python3 n'est pas installé et l'installation automatique n'est pas supportée pour votre système${NC}"
            echo "Veuillez installer Python3 manuellement"
            exit 1
            ;;
    esac
    
    # Vérifier à nouveau après installation
    if ! command_exists python3; then
        echo -e "${RED}Échec de l'installation de Python3${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✓ Python3 trouvé: $(python3 --version)${NC}"

# Vérifier pipenv
if ! command_exists pipenv; then
    echo -e "${YELLOW}pipenv non trouvé, installation en cours...${NC}"
    install_pipenv
else
    echo -e "${GREEN}✓ pipenv trouvé: $(pipenv --version)${NC}"
fi

# Vérifier si on est dans le bon répertoire
if [ ! -f "Pipfile" ]; then
    echo -e "${RED}Pipfile non trouvé dans le répertoire courant${NC}"
    exit 1
fi

# Installer/Mettre à jour l'environnement
echo -e "${YELLOW}Installation/mise à jour de l'environnement Ansible...${NC}"

# Vérifier la version de Python et utiliser le bon Pipfile
PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
echo -e "${GREEN}Version Python détectée: ${PYTHON_VERSION}${NC}"

if python3 -c "import sys; sys.exit(0 if sys.version_info >= (3, 9) else 1)" 2>/dev/null; then
    echo -e "${GREEN}Utilisation du Pipfile standard (Python >= 3.9)${NC}"
    pipenv install
else
    echo -e "${YELLOW}Utilisation du Pipfile compatible Python 3.8${NC}"
    if [ -f "Pipfile.python38" ]; then
        cp Pipfile.python38 Pipfile.backup
        cp Pipfile Pipfile.original
        cp Pipfile.python38 Pipfile
        pipenv install
        # Restaurer le Pipfile original
        cp Pipfile.original Pipfile
        rm -f Pipfile.backup Pipfile.original
    else
        echo -e "${YELLOW}Pipfile pour Python 3.8 non trouvé, tentative avec le Pipfile standard...${NC}"
        pipenv install
    fi
fi

# Vérifier l'installation d'Ansible
echo -e "${YELLOW}Vérification de l'installation d'Ansible...${NC}"
if pipenv run ansible --version >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Ansible installé avec succès${NC}"
    pipenv run ansible --version
else
    echo -e "${RED}Erreur lors de l'installation d'Ansible${NC}"
    exit 1
fi

echo -e "${GREEN}=== Environnement Ansible prêt ! ===${NC}"
echo -e "${YELLOW}Pour utiliser Ansible, préfixez vos commandes avec: ${GREEN}pipenv run${NC}"
echo -e "Exemple: ${GREEN}pipenv run ansible-playbook mon-playbook.yml${NC}"
