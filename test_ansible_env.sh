#!/bin/bash

#
# Script de test pour vérifier l'installation Ansible
# Teste les fonctionnalités de base
#

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Test de l'environnement Ansible ===${NC}"

# Test 1: Vérifier pipenv
echo -e "${YELLOW}Test 1: Vérification de pipenv...${NC}"
if command -v pipenv >/dev/null 2>&1; then
    echo -e "${GREEN}✓ pipenv disponible: $(pipenv --version)${NC}"
else
    echo -e "${RED}✗ pipenv non trouvé${NC}"
    exit 1
fi

# Test 2: Vérifier l'environnement virtuel
echo -e "${YELLOW}Test 2: Vérification de l'environnement virtuel...${NC}"
if pipenv --venv >/dev/null 2>&1; then
    VENV_PATH=$(pipenv --venv)
    echo -e "${GREEN}✓ Environnement virtuel: $VENV_PATH${NC}"
else
    echo -e "${RED}✗ Environnement virtuel non configuré${NC}"
    exit 1
fi

# Test 3: Vérifier Ansible
echo -e "${YELLOW}Test 3: Vérification d'Ansible...${NC}"
if pipenv run ansible --version >/dev/null 2>&1; then
    ANSIBLE_VERSION=$(pipenv run ansible --version | head -n1)
    echo -e "${GREEN}✓ Ansible disponible: $ANSIBLE_VERSION${NC}"
else
    echo -e "${RED}✗ Ansible non trouvé dans l'environnement${NC}"
    exit 1
fi

# Test 4: Vérifier ansible-playbook
echo -e "${YELLOW}Test 4: Vérification d'ansible-playbook...${NC}"
if pipenv run ansible-playbook --version >/dev/null 2>&1; then
    echo -e "${GREEN}✓ ansible-playbook disponible${NC}"
else
    echo -e "${RED}✗ ansible-playbook non trouvé${NC}"
    exit 1
fi

# Test 5: Vérifier ansible-lint
echo -e "${YELLOW}Test 5: Vérification d'ansible-lint...${NC}"
if pipenv run ansible-lint --version >/dev/null 2>&1; then
    LINT_VERSION=$(pipenv run ansible-lint --version)
    echo -e "${GREEN}✓ ansible-lint disponible: $LINT_VERSION${NC}"
else
    echo -e "${YELLOW}⚠ ansible-lint non trouvé (optionnel)${NC}"
fi

# Test 6: Vérifier yamllint
echo -e "${YELLOW}Test 6: Vérification de yamllint...${NC}"
if pipenv run yamllint --version >/dev/null 2>&1; then
    YAML_VERSION=$(pipenv run yamllint --version)
    echo -e "${GREEN}✓ yamllint disponible: $YAML_VERSION${NC}"
else
    echo -e "${YELLOW}⚠ yamllint non trouvé (optionnel)${NC}"
fi

# Test 7: Test de connectivité locale
echo -e "${YELLOW}Test 7: Test de connectivité locale...${NC}"
if pipenv run ansible localhost -m ping >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Connectivité locale OK${NC}"
else
    echo -e "${YELLOW}⚠ Test de connectivité locale échoué (normal si SSH non configuré)${NC}"
fi

# Test 8: Vérifier la syntaxe d'un playbook existant
echo -e "${YELLOW}Test 8: Vérification de la syntaxe des playbooks...${NC}"
PLAYBOOKS_FOUND=0
for playbook in *.yml; do
    if [ -f "$playbook" ] && grep -q "hosts:" "$playbook" 2>/dev/null; then
        if pipenv run ansible-playbook --syntax-check "$playbook" >/dev/null 2>&1; then
            echo -e "${GREEN}✓ Syntaxe OK: $playbook${NC}"
        else
            echo -e "${RED}✗ Erreur de syntaxe: $playbook${NC}"
        fi
        PLAYBOOKS_FOUND=1
    fi
done

if [ $PLAYBOOKS_FOUND -eq 0 ]; then
    echo -e "${YELLOW}⚠ Aucun playbook trouvé pour test de syntaxe${NC}"
fi

echo -e "${GREEN}=== Tests terminés ===${NC}"
echo -e "${GREEN}L'environnement Ansible est opérationnel !${NC}"
echo ""
echo -e "${YELLOW}Commandes utiles:${NC}"
echo "  pipenv shell                    # Activer l'environnement"
echo "  pipenv run ansible --version    # Voir la version d'Ansible"
echo "  pipenv run ansible-playbook ... # Exécuter un playbook"
echo "  ./ansible.sh help              # Voir les commandes d'aide"
