#!/bin/bash

# BF Stay - Deploy a Cloudflare Pages
# Uso: ./scripts/deploy_web.sh

set -e

echo "🚀 BF Stay - Deploy a Cloudflare Pages"
echo ""

# Verificar si wrangler está instalado
if ! command -v wrangler &> /dev/null; then
    echo "📦 Instalando Wrangler CLI..."
    npm install -g wrangler
fi

# Configuración
PROJECT_NAME="bf-stay"
BUILD_DIR="build/web"

echo "📦 Ejecutando build web..."
bash scripts/build_web.sh --quiet

echo ""
echo "📤 Subiendo a Cloudflare Pages..."
echo "   Proyecto: $PROJECT_NAME"
echo ""

# Deploy a Cloudflare Pages (production)
wrangler pages deploy $BUILD_DIR --project-name=$PROJECT_NAME --branch=main --commit-dirty=true

echo ""
echo "✅ Deploy completado!"
echo ""
echo "🌐 Tu aplicación está disponible en:"
echo "   https://bf-stay.pages.dev"
