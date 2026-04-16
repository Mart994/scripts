#!/bin/bash

show_help() {
  echo "Uso:"
  echo "  $0 <nombre_playlist> [directorio]"
  echo
  echo "Descripción:"
  echo "  Crea una playlist M3U8 con archivos FLAC."
  echo
  echo "Argumentos:"
  echo "  nombre_playlist   Nombre del archivo (sin .m3u8)"
  echo "  directorio        Carpeta a escanear (opcional, default: actual)"
  echo
  echo "Opciones:"
  echo "  -h, --help        Mostrar esta ayuda"
  echo
  echo "Ejemplos:"
  echo "  $0 techno"
  echo "  $0 techno \"Tech house 2026\""
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  show_help
  exit 0
fi

# Validar argumento obligatorio
if [ -z "$1" ]; then
  echo "Error: falta el nombre de la playlist"
  echo
  show_help
  exit 1
fi

PLAYLIST_NAME="$1"
DIR="${2:-.}"   # Si no pasás carpeta, usa la actual
OUTPUT="${PLAYLIST_NAME}.m3u8"

echo "#EXTM3U" > "$OUTPUT"

find "$DIR" -type f -iname "*.flac" -print0 | sort -z | while IFS= read -r -d '' file; do
  rel="${file#$DIR/}"
  echo "$rel" >> "$OUTPUT"
done

echo "Playlist creada: $OUTPUT"
