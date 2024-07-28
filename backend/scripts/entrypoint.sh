#!/bin/bash
set -e

echo "▶️ Plone OCI-Image entrypoint entered"

echo "🔀 get settings from environment variables"
/venv/bin/python /site/deployment/transform_from_environment.py -o $ZOPE_CONFIGURATION_FILE

echo "🔧 generate Plone (Zope) instance configuration"
make zope-instance

if [[ "$1" == "start" ]]; then
    echo "🌐 running Plone"
    make zope-start
elif [[ "$1" == "create" ]]; then
    echo "✨ creating new Plone site"
    make plone-site-create
elif [[ "$1" == "export" ]]; then
    echo "📤 exporting to filestorage"
    /venv/bin/zodbconvert --clear /site/instance/etc/relstorage-export.conf
elif [[ "$1" == "import" ]]; then
    echo "📥 importing from filestorage"
    /venv/bin/zodbconvert --clear /site/instance/etc/relstorage-import.conf
elif [[ "$1" == "pack" ]]; then
    echo "🗜️ packing"
    /venv/bin/zodbpack /site/instance/etc/relstorage-pack.conf
else
  echo "⌨️ execute custom command: $@"
  exec "$@"
fi
echo "⏏️ Exit Plone OCI-Image entrypoint."
