#!/bin/bash
set -e

echo "▶️ Plone OCI-Image entrypoint entered"

echo "⚙️ fetch configuration from environment"
/venv/bin/python /site/deployment/transform_from_environment.py -o $ZOPE_CONFIGURATION_FILE

echo "⚙ generate instance from configuration"
make zope-instance

if [[ "$1" == "start" ]]; then
    echo "🌐 running Plone"
    make zope-start
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
