#!/bin/bash

set -e

python cfgov/manage.py runmodwsgi 
--port 8000 \
--log-to-terminal \
--working-directory /src/cfgov-refresh/
--entry-point /src/cfgov-refresh/cfgov/cfgov/wsgi.py
#--include-file /src/cfgov-refresh/cfgov/apache/include.conf \
#$EXTRA_MODWSGI_ARGS