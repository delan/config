#!/usr/bin/env zsh
set -eu
while read -r href; do
    read -r src
    href=$(printf \%s "$href" | rg --pcre2 -o '(?<=<).+(?=>)')
    src=$(printf \%s "$src" | rg --pcre2 -o '(?<=<).+(?=>)')
    printf '[![](%s)](%s)\n\n' "$src" "$href"
    photo-details.sh "$href"
    echo
done
