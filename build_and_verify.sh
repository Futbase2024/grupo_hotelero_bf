#!/bin/zsh

set -e  # parar si falla algo

APP_NAME="futbase"
BUILD_DIR="build/app/outputs/bundle/release"
AAB_PATH="$BUILD_DIR/app-release.aab"
EXTRACT_DIR="aab_extract"

echo "🧹 Limpiando proyecto..."
fvm flutter clean

echo "📦 Compilando AAB solo para ARM (armeabi-v7a y arm64-v8a)..."
fvm flutter build appbundle \
  --target-platform=android-arm,android-arm64 \
  --release

if [ ! -f "$AAB_PATH" ]; then
  echo "❌ No se encontró el AAB en $AAB_PATH"
  exit 1
fi

echo "📂 Extrayendo librerías nativas del AAB..."
rm -rf "$EXTRACT_DIR"
mkdir -p "$EXTRACT_DIR"
unzip -q "$AAB_PATH" "base/lib/**/*.so" -d "$EXTRACT_DIR"

echo "🔍 Verificando alineación de páginas en librerías..."
PROBLEMATIC=0
for sofile in $(find "$EXTRACT_DIR" -name "*.so"); do
  echo "📄 Revisando $sofile"
  ALIGNMENTS=$(llvm-objdump -p "$sofile" | grep "LOAD" | awk '{print $NF}')

  for align in $ALIGNMENTS; do
    if [[ "$align" == "2**"*"14" ]] || [[ "$align" == "2**"*"15" ]] || [[ "$align" == "2**"*"16" ]]; then
      echo "   ✅ OK ($align)"
    else
      echo "   ❌ NO COMPATIBLE ($align)"
      PROBLEMATIC=1
    fi
  done
done

if [ $PROBLEMATIC -eq 0 ]; then
  echo "🎉 Todas las librerías cumplen con alineación ≥ 16KB"
else
  echo "⚠️ Algunas librerías no cumplen con alineación ≥ 16KB"
  exit 1
fi
