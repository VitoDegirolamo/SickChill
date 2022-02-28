FROM python:3.9-slim

LABEL org.opencontainers.image.source="https://github.com/sickchill/sickchill"
LABEL maintainer="vito.degirolamo88@gmail.com"
ENV PYTHONIOENCODING="UTF-8"
ENV PIP_FIND_LINKS=https://wheel-index.linuxserver.io/ubuntu/
ENV POETRY_INSTALLER_PARALLEL=false
ENV POETRY_VIRTUALENVS_CREATE=true
ENV POETRY_VIRTUALENVS_IN_PROJECT=true

VOLUME /data 

EXPOSE 8081

RUN useradd -u 1001 -d /home/chicco chicco && \
    mkdir -p /home/chicco /var/run/sickchill /app/sickchill && \
    chown -R chicco. /home/chicco /app/sickchill && \
    chmod -R +w /home/chicco && \
    sed -i -e's/ main/ main contrib non-free/gm' /etc/apt/sources.list && \
    apt-get update -qq && apt-get install -yq git gosu libxml2 libxml2-dev \
    libxslt1.1 libxslt1-dev libffi7 libffi-dev libssl1.1 libssl-dev python3-dev \
    libmediainfo0v5 libmediainfo-dev mediainfo unrar curl build-essential && \
    apt-get clean -yqq && \
    rm -rf /var/lib/apt/lists/* && \
    python -m pip install --upgrade pip

USER chicco
ENV PATH="/home/chicco/.local/bin:${PATH}"

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \ 
    . $HOME/.cargo/env && \
    pip3 install --upgrade --prefer-binary poetry pip wheel setuptools

WORKDIR /app/sickchill
COPY . /app/sickchill

RUN . $HOME/.cargo/env && \
    poetry install --no-root --no-interaction --no-ansi

CMD poetry run python3 /app/sickchill/SickChill.py --nolaunch --datadir=/data --port 8081
 
HEALTHCHECK --interval=5m --timeout=3s \
   CMD curl -f http://localhost:8081/sickchill || curl -f https://localhost:8081/sickchill || exit 1
