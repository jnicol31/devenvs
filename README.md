# devenvs
Images de compilation et modèles Dev Containers, utilisés depuis VS Code (Windows)

## Makefile

```bash
make build            # toutes les images (ou : make build sys)
make push sys         # envoie devenv-sys sur le m720q (HOST=srv-m720q par défaut)
make check            # hadolint, shellcheck + shfmt, JSON valides
```

En usage normal, le dépôt est cloné sur le m720q (`~/dev/envs`) et `make build` y
construit directement dans le Docker rootless de l'utilisateur : `make push` ne sert
que si l'on construit ailleurs (`docker save | ssh <hôte> docker load`, sans registre).

## `sys` : contrôleur Ansible

L'image `devenv-sys` sert de machine d'administration : Ansible (`ansible-core`
2.20 dans un venv, collections `ansible.posix`, `community.docker`,
`community.general`), `ansible-lint`, `yamllint`, `shellcheck`, `shfmt`, `make`,
`git`, `jq`, `rsync`, `sops`, `age` et le client SSH.

```bash
scripts/build.sh sys
scripts/devinit.sh homelab sys     # après avoir cloné le dépôt homelab dans ~/dev/projects/homelab
```

Ouvrir ensuite `~/dev/projects/homelab` dans VS Code (Remote-SSH puis « Reopen in Container »).

- **Réseau :** le conteneur tourne sur le m720q, donc sur le LAN, quelle que soit
  la façon dont VS Code atteint le m720q (LAN ou bastion). On y utilise
  `ansible/inventory/hosts.yml` (accès direct) ; `remote.yml` reste possible (saut
  par le bastion) mais inutile depuis le LAN. L'utilisateur de connexion est celui
  de la session SSH sur le m720q (`ANSIBLE_REMOTE_USER`).
- **Clés SSH :** aucune clé privée dans l'image ni montée. VS Code relaie l'agent de
  ton poste : dans `~/.ssh/config` côté poste, `ForwardAgent yes` pour le m720q
  (et pour le saut par le bastion si tu utilises `remote.yml`). Vérifier avec
  `ssh-add -l` dans le conteneur.
- **Premiers accès :** `~/dev/cache/ssh` est monté sur `/root/.ssh` et ne contient que
  `known_hosts`. Se connecter une fois à la main à chaque hôte
  (`ssh <hôte>`) pour en accepter l'empreinte ; elle est ensuite conservée.
- **Clé age admin :** jamais dans le conteneur. Les playbooks n'en ont pas besoin
  (chaque hôte déchiffre avec sa propre clé) ; le rechiffrement des secrets se fait
  depuis le poste de l'administrateur.
