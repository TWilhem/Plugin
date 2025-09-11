Anaconda() {
    # Charger conda
    source ~/anaconda3/etc/profile.d/conda.sh

    # Lister les environnements et stocker dans un tableau
    mapfile -t envs < <(conda env list | awk '{print $1}' | grep -vE '^#|^$')

    # Construire le menu pour dialog (nom et description)
    menu_items=()
    for env in "${envs[@]}"; do
        menu_items+=("$env" "Environnement Conda")
    done

    # Lancer le menu interactif pour un seul choix
    selected=$(dialog --clear --stdout --menu "Sélectionnez l'environnement :" 20 60 15 "${menu_items[@]}")

    # Nettoyer l’écran après dialog
    clear

    # Sauvegarder les clés sélectionnées
    if [[ -n "$selected" ]]; then
        echo "Activation de l'environnement '$selected'..."
        conda activate $selected

        # Apparence du terminal
        PS1="$PS1" bash --noprofile --norc

        # Sorti du sous terminal
        conda deactivate
        echo "Sorti de l'environnement '$selected'."

    else
        echo "Activation de aucun environnement"
    fi
}
