#!/bin/bash

set -eux

filename="$1"
echo "watching updates of '$filename'"

set +e
satyhs=($(find ** | grep -e '.satyh' -e '.satyg' -e '.bib'))
if [ $? = 0 ]; then
  echo "deps: ${satyhs[@]}"
  fswatch -o "$filename" "${satyhs[@]}" | xargs -I{} time "$(rm *.satysfi-aux; satysfi "$filename" -o "${filename%%.*}.pdf")" | tee output.log
else
  fswatch -o "$filename" | xargs -I{} time "$(rm *.satysfi-aux; satysfi "$filename" -o "${filename%%.*}.pdf")" | tee output.log
fi



