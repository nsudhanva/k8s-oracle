#!/bin/sh
find "${HOME}/.openclaw/browser" -name "Singleton*" -delete 2>/dev/null || true
exec openclaw gateway --allow-unconfigured "$@"
