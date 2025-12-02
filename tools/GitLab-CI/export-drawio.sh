#!/bin/bash

ANSI_LIGHT_GREEN=$'\x1b[92m'
ANSI_LIGHT_YELLOW=$'\x1b[93m'
ANSI_LIGHT_BLUE=$'\x1b[94m'
ANSI_NOCOLOR=$'\x1b[0m'

for file in "$@"; do
    base_name="${file%.*}"

    # Count how many pages exist per *.drawio file. Use "diagram" tag as indication. Also extract page names.
    mapfile -t names < <(sed -nE  's/.*<diagram.*name="([^"]*).*/\1/p' "$file")
    printf "${ANSI_LIGHT_YELLOW}Exporting from '$base_name'${ANSI_NOCOLOR}\n"

    # Export each page as an PNG
    for i in "${!names[@]}"; do
        printf "  ${ANSI_LIGHT_BLUE}page '${names[i]}' ...${ANSI_NOCOLOR}\n"
        drawio --export --page-index $((i+1)) --no-sandbox --crop --border 5 --output "${base_name}_${names[i]}.png" "$file"
    done
done

printf "${ANSI_LIGHT_YELLOW}Waiting for exports to finish ...${ANSI_NOCOLOR}\n"
wait

printf "${ANSI_LIGHT_GREEN}Finished export${ANSI_NOCOLOR}\n"
