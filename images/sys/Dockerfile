# Contrôleur d'administration : Ansible (venv), outils de lint, sops/age, client SSH.
# Aucune clé dans l'image : l'agent SSH est relayé par VS Code, la clé age admin
# reste sur le poste de l'administrateur.
ARG ANSIBLE_CORE_VERSION=2.20
ARG SOPS_VERSION=3.13.3
ARG SOPS_SHA256=e5bec3346a873ae91d871550f3e698c1aad962aff462a080e40f25fde17fef6b

FROM debian:trixie-slim

ARG ANSIBLE_CORE_VERSION
ARG SOPS_VERSION
ARG SOPS_SHA256

ENV PATH="/opt/ansible/bin:${PATH}" \
    ANSIBLE_COLLECTIONS_PATH="/opt/ansible/collections"

# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        age \
        bash \
        ca-certificates \
        curl \
        docker-cli \
        git \
        jq \
        make \
        openssh-client \
        python3 \
        python3-venv \
        rsync \
        shellcheck \
        shfmt \
        yamllint \
    && rm -rf /var/lib/apt/lists/*

# ansible-core est épinglé sur la version mineure utilisée sur le poste
# d'administration (correctifs de sécurité inclus) ; ansible-lint suit.
# Collections : celles du requirements.yml du dépôt homelab.
# hadolint ignore=DL3013
RUN python3 -m venv /opt/ansible \
    && /opt/ansible/bin/pip install --no-cache-dir \
        "ansible-core~=${ANSIBLE_CORE_VERSION}.0" \
        ansible-lint \
    && /opt/ansible/bin/ansible-galaxy collection install \
        --collections-path "${ANSIBLE_COLLECTIONS_PATH}" \
        ansible.posix community.docker community.general \
    && for executable in /opt/ansible/bin/ansible*; do \
        ln -s "$executable" "/usr/local/bin/${executable##*/}"; \
    done

# sops : version et empreinte épinglées (amd64).
RUN curl -fsSL \
        "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux.amd64" \
        -o /usr/local/bin/sops \
    && echo "${SOPS_SHA256}  /usr/local/bin/sops" | sha256sum -c - \
    && chmod 0755 /usr/local/bin/sops \
    && apt-get purge -y --auto-remove curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
