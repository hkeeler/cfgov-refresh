# docker-entrypoint-initdb.d

This directory is used for loading Postgres database scripts and dumps at container startup.

For detail on how this works, see `postgres` image's docs on
[https://github.com/docker-library/docs/tree/master/postgres#initialization-scripts](https://github.com/docker-library/docs/tree/master/postgres#initialization-scripts).

For details on load cf.gov database dumps, see
[Load a database dump](https://cfpb.github.io/cfgov-refresh/installation/#load-a-database-dump).
