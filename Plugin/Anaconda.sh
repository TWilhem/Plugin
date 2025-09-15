Anaconda() {
    SAUVFILE=~/.Plugin/Plugin/Anaconda.txt

    # Charger conda
    source ~/anaconda3/etc/profile.d/conda.sh

    # Lister les environnements conda disponibles
    mapfile -t envs < <(conda env list | awk '{print $1}' | grep -vE '^#|^$')

    # Lire les environnements déjà enregistrés dans le fichier
    declare -A saved_paths
    if [[ -f "$SAUVFILE" ]]; then
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            # Séparer sur le premier '--'
            name="${line%%--*}"
            path="${line#*--}"
            name=$(echo "$name" | xargs)
            path=$(echo "$path" | xargs)
            saved_paths["$name"]="$path"
        done < "$SAUVFILE"
    else
        > "$SAUVFILE"
    fi

    # Ajouter les nouveaux environnements manquants
    for env in "${envs[@]}"; do
        if [[ -z "${saved_paths[$env]}" ]]; then
            echo "$env -- ./" >> "$SAUVFILE"
            saved_paths["$env"]="./"
        fi
    done

    # Menu boucle : permet de modifier ou activer
    while true; do
        # Construire le menu
        menu_items=()
        for env in "${envs[@]}"; do
            desc="${saved_paths[$env]}"
            [[ -z "$desc" ]] && desc="./"
            menu_items+=("$env" "$desc")
        done

        # Afficher le menu
        exec 3>&1
        selection=$(dialog --clear --stdout \
            --extra-button --extra-label "Parametre" \
            --menu "Sélectionnez l'environnement" \
            20 60 15 "${menu_items[@]}")
        exit_code=$?
        exec 3>&-

        clear

        # Si bouton "Parametre" pressé (code 3)
        if [[ $exit_code -eq 3 ]]; then
            if [[ -n "$selection" ]]; then
                # Demander le nouveau commentaire
                new_comment=$(dialog --clear --stdout --inputbox \
                    "Modifier le commentaire pour '$selection':" 10 60 "${saved_paths[$selection]}")

                clear

                if [[ -n "$new_comment" ]]; then
                    # Mettre à jour en mémoire et le fichier 
                    saved_paths["$selection"]="$new_comment"
                    > "$SAUVFILE"
                    for e in "${!saved_paths[@]}"; do
                        echo "$e -- ${saved_paths[$e]}" >> "$SAUVFILE"
                    done
                    echo "Commentaire de '$selection' mis à jour en '$new_comment'."
                fi
            fi
            # Revenir au menu
            continue
        fi

        # Si annulation
        if [[ $exit_code -ne 0 ]]; then
            echo "Aucun environnement sélectionné."
            return
        fi

        # Si OK (activation)
        if [[ -n "$selection" ]]; then
            echo "Activation de l'environnement '$selection'..."
            selected_path="${saved_paths[$selection]}"
            expanded_path="${selected_path/#\~/$HOME}"

            # Lancer tout dans un sous-shell pour ne pas changer le cwd du shell principal
            current_ps1="$PS1"
            bash --noprofile --norc -i -c "
                source ~/anaconda3/etc/profile.d/conda.sh
                conda activate \"$selection\"
                cd \"$expanded_path\" || exit
                export PS1=\"(\$CONDA_DEFAULT_ENV) $current_ps1\"
                bash --noprofile --norc
                conda deactivate
            "

            echo "Sorti de l'environnement '$selection'."
        fi
        break
    done
}
