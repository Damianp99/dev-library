$ErrorActionPreference = "Stop"

Write-Host "Installazione dipendenze..."
py -m pip install -r requirements.txt

Write-Host "Avvio MkDocs..."
$env:PYTHONIOENCODING = "utf-8"
py -m mkdocs serve --livereload --watch docs --watch styles.css
