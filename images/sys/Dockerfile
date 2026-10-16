# Contrôleur d'administration : Ansible (venv), outils de lint, sops/age, client SSH.
# Aucune clé dans l'image : l'agent SSH est relayé par VS Code, la clé age admin
# reste sur le poste de l'administrateur.
ARG ANSIBLE_CORE_VERSION=2.20
ARG SOPS_VERSION=3.13.3
ARG SOPS_SHA256=e5bec3346a873ae91d871550f3e698c1aad962aff462a080e40f25fde17fef6b
# shellcheck de Debian (0.10) est en retard sur celui du dépôt homelab (codes SC2329...).
ARG SHELLCHECK_VERSION=0.11.0
ARG SHELLCHECK_SHA256=8c3be12b05d5c177a04c29e3c78ce89ac86f1595681cab149b65b97c4e227198

FROM debian:trixie-slim

# Un échec en amont d'un pipe (ex. sha256sum) fait échouer le RUN.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG ANSIBLE_CORE_VERSION
ARG SOPS_VERSION
ARG SOPS_SHA256
ARG SHELLCHECK_VERSION
ARG SHELLCHECK_SHA256

# Locale : l'image n'a que C, C.utf8 et POSIX. Sans LC_ALL, le LANG=en_US.UTF-8
# transmis par VS Code fait échouer ansible-config (« unsupported locale setting »).
# Rôles : le dépôt monté dans /workspace range ses rôles dans ansible/roles ; sans
# cela, ansible-lint (qui vérifie chaque rôle isolément) ne trouve pas les rôles
# voisins (import_role).
ENV PATH="/opt/ansible/bin:${PATH}" \
    LANG="C.UTF-8" \
    LC_ALL="C.UTF-8" \
    ANSIBLE_COLLECTIONS_PATH="/opt/ansible/collections" \
    ANSIBLE_ROLES_PATH="/workspace/ansible/roles"

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
        shfmt \
        xz-utils \
        yamllint \
        tig \
        less \
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

# shellcheck : version et empreinte épinglées (amd64).
RUN curl -fsSL \
        "https://github.com/koalaman/shellcheck/releases/download/v${SHELLCHECK_VERSION}/shellcheck-v${SHELLCHECK_VERSION}.linux.x86_64.tar.xz" \
        -o /tmp/shellcheck.tar.xz \
    && echo "${SHELLCHECK_SHA256}  /tmp/shellcheck.tar.xz" | sha256sum -c - \
    && tar -xJf /tmp/shellcheck.tar.xz -C /tmp \
    && install -m 0755 "/tmp/shellcheck-v${SHELLCHECK_VERSION}/shellcheck" /usr/local/bin/shellcheck \
    && rm -rf /tmp/shellcheck.tar.xz "/tmp/shellcheck-v${SHELLCHECK_VERSION}"

# sops : version et empreinte épinglées (amd64).
RUN curl -fsSL \
        "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux.amd64" \
        -o /usr/local/bin/sops \
    && echo "${SOPS_SHA256}  /usr/local/bin/sops" | sha256sum -c - \
    && chmod 0755 /usr/local/bin/sops \
    && apt-get purge -y --auto-remove curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
