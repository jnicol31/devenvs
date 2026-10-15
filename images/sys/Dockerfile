ARG ANSIBLE_VERSION=11.5.0
ARG SOPS_VERSION=3.10.2

FROM debian:trixie-slim

ARG ANSIBLE_VERSION
ARG SOPS_VERSION

ENV PATH="/opt/ansible/bin:${PATH}"

# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        age \
        bash \
        ca-certificates \
        curl \
        docker-cli \
        python3 \
        python3-venv \
        shellcheck \
        shfmt \
        yamllint \
    && python3 -m venv /opt/ansible \
    && /opt/ansible/bin/pip install --no-cache-dir "ansible==${ANSIBLE_VERSION}" \
    && for executable in /opt/ansible/bin/ansible*; do \
        ln -s "$executable" "/usr/local/bin/${executable##*/}"; \
    done \
    && curl -fsSL \
        "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux.amd64" \
        -o /usr/local/bin/sops \
    && chmod +x /usr/local/bin/sops \
    && apt-get purge -y --auto-remove curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
