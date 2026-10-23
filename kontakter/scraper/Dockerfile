FROM ubuntu:latest@sha256:c098726dd9b9733f3e885f8de0ef375206a311b0a317eadc40d347b1115fb944

WORKDIR /app

# ubuntu:latest är alltid senaste Ubuntu LTS. Playwright installeras med pip i
# en venv, och webbläsaren med `playwright install`, så att webbläsaren alltid
# matchar Playwright-versionen i requirements.txt. Systempaketen uppgraderas
# vid bygget; pip och venv-verktygen tas bort efteråt.
ENV DEBIAN_FRONTEND=noninteractive \
    VIRTUAL_ENV=/opt/venv \
    PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"

COPY requirements.txt .
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends ca-certificates python3 python3-venv \
    && python3 -m venv "${VIRTUAL_ENV}" \
    && "${VIRTUAL_ENV}/bin/python" -m pip install --no-cache-dir -r requirements.txt \
    && playwright install --with-deps chromium \
    && "${VIRTUAL_ENV}/bin/python" -m pip uninstall --yes pip \
    && apt-get purge -y python3-venv "python3.$(python3 -c 'import sys; print(sys.version_info.minor)')-venv" python3-pip-whl python3-setuptools-whl \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* /root/.cache \
    && "${VIRTUAL_ENV}/bin/python" -c "import importlib.metadata as m; print('venv idna', m.version('idna')); print('venv setuptools', m.version('setuptools')); print('venv msgpack', m.version('msgpack')); print('playwright', m.version('playwright'))"

COPY scraper.py politiker_common.py sources.py ./
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]
