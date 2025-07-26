#!/bin/bash

#
# Script d'aide pour les commandes Ansible courantes
# Utilise automatiquement pipenv
#

set -e

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Vérifier que pipenv est configuré
if ! pipenv run ansible --version >/dev/null 2>&1; then
    echo -e "${YELLOW}Environnement Ansible non configuré. Exécution de la configuration...${NC}"
    ./setup_ansible_env.sh
fi

# Fonction d'aide
show_help() {
    echo -e "${GREEN}Commandes Ansible disponibles:${NC}"
    echo ""
    echo "  ./ansible.sh playbook <fichier.yml>  - Exécuter un playbook"
    echo "  ./ansible.sh ping                    - Tester la connectivité"
    echo "  ./ansible.sh lint <fichier.yml>      - Vérifier la syntaxe"
    echo "  ./ansible.sh vault-encrypt <fichier> - Chiffrer un fichier"
    echo "  ./ansible.sh vault-decrypt <fichier> - Déchiffrer un fichier"
    echo "  ./ansible.sh galaxy-install          - Installer les rôles Galaxy"
    echo "  ./ansible.sh shell                   - Ouvrir un shell pipenv"
    echo ""
    echo "Exemples:"
    echo "  ./ansible.sh playbook raspian_first_boot.yml"
    echo "  ./ansible.sh ping"
    echo "  ./ansible.sh lint *.yml"
}

# Traitement des commandes
case "${1:-help}" in
    "playbook")
        if [ -z "$2" ]; then
            echo "Usage: ./ansible.sh playbook <fichier.yml>"
            exit 1
        fi
        echo -e "${GREEN}Exécution du playbook: $2${NC}"
        pipenv run ansible-playbook \
            --extra-vars="raspian_first_boot_pi_pub_key=keys/pi_id_rsa.pub" \
            --extra-vars="raspian_first_boot_ssh_port=1976" \
            --inventory inventory/ \
            --ask-pass \
            -vvv "$2"
        ;;
    "ping")
        echo -e "${GREEN}Test de connectivité...${NC}"
        pipenv run ansible all -i inventory/ -m ping --ask-pass
        ;;
    "lint")
        shift
        files="${@:-*.yml}"
        echo -e "${GREEN}Vérification de la syntaxe: $files${NC}"
        pipenv run ansible-lint $files
        pipenv run yamllint $files
        ;;
    "vault-encrypt")
        if [ -z "$2" ]; then
            echo "Usage: ./ansible.sh vault-encrypt <fichier>"
            exit 1
        fi
        echo -e "${GREEN}Chiffrement du fichier: $2${NC}"
        pipenv run ansible-vault encrypt "$2"
        ;;
    "vault-decrypt")
        if [ -z "$2" ]; then
            echo "Usage: ./ansible.sh vault-decrypt <fichier>"
            exit 1
        fi
        echo -e "${GREEN}Déchiffrement du fichier: $2${NC}"
        pipenv run ansible-vault decrypt "$2"
        ;;
    "galaxy-install")
        echo -e "${GREEN}Installation des rôles Galaxy...${NC}"
        if [ -f "requirements.yml" ]; then
            pipenv run ansible-galaxy install -r requirements.yml
        else
            echo "Fichier requirements.yml non trouvé"
        fi
        ;;
    "shell")
        echo -e "${GREEN}Ouverture du shell pipenv...${NC}"
        pipenv shell
        ;;
    "help"|*)
        show_help
        ;;
esac
