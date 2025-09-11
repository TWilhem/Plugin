#!/bin/bash

# Installation paquet dialog
if dpkg -s dialog >/dev/null 2>&1; then
    echo "Paquet dialog déjà installé"
else
    echo "Installation du paquet dialog"
    sudo apt-get update
    sudo apt-get install dialog -y
fi

# Creation du repertoire si inexistant
Github_DIR="https://raw.githubusercontent.com/TWilhem/Plugin/main"
Script_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -d "$Script_DIR/Plugin" ]; then
    echo "Creation repertoire Plugin"
    mkdir ~/.Plugin/Plugin
else
    echo "Repertoire Plugin existant"
fi

Script_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
Plugin_File=($(find "$Script_DIR" -maxdepth 1 -type f -exec basename {} \;))


# Recuperation de la liste de plugin
curl -fsSL "$Github_DIR/List" -o "$Script_DIR/List"
if [[ ! -f "$Script_DIR/List" ]]; then
    exit 1
fi
mapfile -t all_plugin < List

# Construire la liste pour dialog
menu_items=()
for k in "${all_plugin[@]}"; do
    if [[ " ${Plugin_File[*]} " == *" $k "* ]]; then
        menu_items+=("$k" "" "on")
    else
        menu_items+=("$k" "" "off")
    fi
done

# Lancer le menu interactif checkbox
selected=$(dialog --clear --stdout --checklist \
    "Sélectionnez les raccourcis a installer, Entrée pour valider) :" 20 60 15 \
    "${menu_items[@]}")

# Nettoyer l’écran après dialog
clear

# Conversion des sélections en tableau
read -r -a selected_plugins <<< "$selected"


# Installation / suppression selon la sélection
for plugin in "${all_plugin[@]}"; do
    if [[ " ${selected_plugins[*]} " == *" $plugin "* ]]; then
        if [[ ! -f "$Script_DIR/Plugin/$plugin" ]]; then
            echo "Ajout de $plugin"
            curl -fsSL "$Github_DIR/Plugin/$plugin" -o "$Script_DIR/Plugin/$plugin"
        else
            echo "$plugin déjà présent"
        fi
    else
        if [[ -f "$Script_DIR/Plugin/$plugin" ]]; then
            echo "Suppression de $plugin"
            rm "$Script_DIR/Plugin/$plugin"
        fi
    fi
done



#create link .bashrc

#echo resultat et commande
