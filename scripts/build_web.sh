#!/bin/bash

# BF Stay - Build Web para Producción
# Uso: ./scripts/build_web.sh [--quiet]

set -e

QUIET=false
if [[ "$1" == "--quiet" ]]; then
    QUIET=true
fi

# Configuración de Supabase
SUPABASE_URL="https://qwepisgdqlmqfxwqkztz.supabase.co"
SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3ZXBpc2dkcWxtcWZ4d3FrenR6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE5MDYxOTIsImV4cCI6MjA4NzQ4MjE5Mn0.pUdETUpzY4wdnK54CVxUdo3BDe0GDFles82IG000SY0"

# Dominio de producción
DOMAIN="https://bf-stay.pages.dev"

if [ "$QUIET" = false ]; then
    echo "🚀 Iniciando build web para BF Stay..."
    echo ""
    echo "📦 Compilando Flutter Web..."
    echo "   URL: $SUPABASE_URL"
    echo "   Dominio: $DOMAIN"
    echo ""
fi

flutter build web --release \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
  --dart-define=ENVIRONMENT=prod \
  --no-tree-shake-icons \
  --no-wasm-dry-run

if [ "$QUIET" = false ]; then
    echo ""
    echo "✅ Build completado!"
    echo ""
    echo "📁 Output: build/web/"
    echo "🌐 Sube esta carpeta a Cloudflare Pages"
    echo ""
    echo "🔗 Recuerda configurar en Supabase:"
    echo "   - Site URL: $DOMAIN"
    echo "   - Redirect URLs: $DOMAIN/**"
fi
