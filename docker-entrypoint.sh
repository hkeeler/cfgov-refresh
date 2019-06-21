#!/bin/sh

# FIXME: Make sure the Dockerfile takes care of this 
#source /opt/rh/${SCL_PYTHON_VERSION}/enable && \

cd cfgov && \
python manage.py collectstatic && \
mod_wsgi-express start-server --log-to-terminal cfgov/wsgi.py