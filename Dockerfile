#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
FROM python:3.6-jessie

RUN useradd --user-group --create-home --no-log-init --shell /bin/bash superset
#COPY sources.list .
#RUN mv /etc/apt/sources.list /etc/apt/sources.list.bak  && mv sources.list /etc/apt/
# Configure environment
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

#RUN apt-get install apt-transport-https

RUN apt-get update -y

# Install dependencies to fix `curl https support error` and `elaying package configuration warning`
RUN apt-get install -y apt-transport-https apt-utils

# Install superset dependencies
# https://superset.incubator.apache.org/installation.html#os-dependencies
RUN apt-get install -y build-essential libssl-dev \
    libffi-dev python3-dev libsasl2-dev libldap2-dev libxi-dev

# Install extra useful tool for development
RUN apt-get install -y vim less postgresql-client redis-tools

# Install nodejs for custom build
# https://superset.incubator.apache.org/installation.html#making-your-own-build
# https://nodejs.org/en/download/package-manager/
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - \
    && apt-get install -y nodejs

#WORKDIR /home/superset
#
COPY requirements.txt .
COPY requirements-dev.txt .

RUN pip install --upgrade setuptools pip -i https://pypi.tuna.tsinghua.edu.cn/simple\
    && pip install -r requirements.txt -r requirements-dev.txt -i https://pypi.tuna.tsinghua.edu.cn/simple\
    && rm -rf /root/.cache/pip

RUN pip install superset -i https://pypi.tuna.tsinghua.edu.cn/simple

COPY --chown=superset:superset superset superset

ENV PATH=/home/superset/superset/bin:$PATH \
    PYTHONPATH=/home/superset/superset/:$PYTHONPATH
ENV SUPERSET_ENV=production

USER superset

RUN cd superset/assets \
    && npm ci \
    && npm run build \
    && rm -rf node_modules

COPY contrib/docker/docker-init.sh .
COPY contrib/docker/docker-entrypoint.sh /entrypoint.sh
RUN sh docker-init.sh
ENTRYPOINT ["/entrypoint.sh"]

HEALTHCHECK CMD ["curl", "-f", "http://localhost:8088/health"]
EXPOSE 8088
