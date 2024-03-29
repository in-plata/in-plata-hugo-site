#!/bin/sh

if [ $# -lt 1 ]
  then
    echo "Uso: $0 credentials_file"
    exit 1
fi


credentials=$1
photos_dir="$HOME/in.plata/fotos" 
catalog_spreadsheet="Catalogo"
catalog_sheet_index=0
catalog_export_dir="/tmp"
catalog_exported_file="$catalog_export_dir/$catalog_spreadsheet.csv"


# download del catalogo
python3 download_spreadsheet.py $credentials $catalog_spreadsheet $catalog_sheet_index -e $catalog_export_dir

# generar contenido del sitio
python3 generate_content.py  $catalog_exported_file $photos_dir -e .

diff=`git status | grep .md | wc -l`

if [ $diff -eq 0 ] 
then
  echo 'No se detectaron cambios, no se actualizó el sitio'
else
  # Guardar los cambios en los sources para mostrar en el resultado
  echo "Archivos modificados"
  echo ""
  git diff --color-words -U0 --src-prefix=Ficha: *.md | grep -v @@ | grep -v index | grep -v diff | grep -v -e "+++ b"

  # Rebuildear y deployar los cambios en el site
  ./deploy.sh > /tmp/deploy.out 2>&1

  # Guardar los cambios en los sources
  git add *.md public > /tmp/add.out 2>&1
  git commit -m "Changes done by update_content script" > /tmp/commit.out 2>&1
  git push origin master > /tmp/push.out 2>&1
fi

