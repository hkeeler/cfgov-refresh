FROM centos:7 AS cfgov-base

# Forces `source /etc/profile` and safer pipe | handling during `docker build`.
# This does not affect shell env for `docker run/exec`. 
SHELL ["/bin/bash", "--login", "-o", "pipefail", "-c"]

# Stops Python default buffering to stdout, improving logging to the console.
ENV PYTHONUNBUFFERED 1

ENV APP_HOME /src/cfgov-refresh
RUN mkdir -p ${APP_HOME}
WORKDIR ${APP_HOME}

# Install common OS packages
RUN yum -y install \
        centos-release-scl \
        epel-release \
        https://download.postgresql.org/pub/repos/yum/10/redhat/rhel-7-x86_64/pgdg-centos10-10-2.noarch.rpm && \
    yum -y install \
        mailcap \
        postgresql10 \
        which && \
    yum clean all

# Specify SCL-based Python version.
# Currently used options: python27, rh-python36
# See: https://www.softwarecollections.org/en/scls/user/rhscl/?search=python
ARG scl_python_version
ENV SCL_PYTHON_VERSION ${scl_python_version}
ENV SCL_PYTHON_ROOT=/opt/rh/${SCL_PYTHON_VERSION}/root

# Install SCL-based Python, and set is as default `python`
RUN yum -y install ${SCL_PYTHON_VERSION} && \
    yum clean all && \
    echo "source scl_source enable ${SCL_PYTHON_VERSION}" > \
         /etc/profile.d/enable_scl_python.sh && \
    source /etc/profile && \
    pip install --no-cache-dir --upgrade pip setuptools

# Disables pip cache. Reduces build time, and suppresses warnings when run as non-root.
# NOTE: MUST be after pip upgrade.  Build fails otherwise due to bug in old pip.
ENV PIP_NO_CACHE_DIR true

EXPOSE 8000

COPY docker-entrypoint.sh ./docker-entrypoint.sh
ENTRYPOINT ["./docker-entrypoint.sh"]


# Image designed for local developement
FROM cfgov-base AS cfgov-develop

RUN yum -y install gcc && yum clean all

# Copy over the script that extends the Python environment with develop-apps
COPY extend-environment.sh /etc/profile.d/extend-environment.sh

# Install python dependencies
COPY requirements requirements
RUN pip install -r requirements/local.txt

CMD ["python", "./cfgov/manage.py", "runserver", "0.0.0.0:8000"]


FROM cfgov-base as cfgov-build

ENV DJANGO_SETTINGS_MODULE=cfgov.settings.production
ENV DJANGO_STATIC_ROOT=/var/www/html/static
ENV ALLOWED_HOSTS='["*"]'

# Add build tools
RUN curl -sL https://dl.yarnpkg.com/rpm/yarn.repo | tee /etc/yum.repos.d/yarn.repo && \
    curl -sL https://rpm.nodesource.com/setup_10.x | bash - && \
    yum -y install \
        gcc \
        httpd-devel \
        nodejs \
        postgresql10-devel \
        yarn && \
    yum clean all

# Install python dependencies
COPY requirements requirements
RUN pip install -r requirements/deployment.txt

# Copy in JUST the files needed to build cf.gov
COPY cfgov ./cfgov
COPY config ./config
COPY gulp ./gulp
COPY static.in ./static.in
COPY scripts ./scripts
COPY frontend.sh \
     gulpfile.js \
     jest.config.js \
     package.json \
     yarn.lock \
     ${APP_HOME}

RUN ./frontend.sh production && \
    cfgov/manage.py collectstatic


FROM cfgov-base as cfgov-deploy

ENV SCL_HTTPD_VERSION=httpd24

RUN yum install -y ${SCL_HTTPD_VERSION} && \
    yum clean all

COPY --from=cfgov-build ${SCL_PYTHON_ROOT}/usr/lib/ ${SCL_PYTHON_ROOT}/usr/lib/
COPY --from=cfgov-build ${SCL_PYTHON_ROOT}/usr/lib64/ ${SCL_PYTHON_ROOT}/usr/lib64/
COPY --from=cfgov-build --chown=apache:apache ${APP_HOME}/cfgov/ ${APP_HOME}/cfgov/
COPY --from=cfgov-build --chown=apache:apache /var/www/html/static /var/www/html/static
