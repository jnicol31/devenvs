# devenvs

Images de compilation et modèles Dev Containers, utilisés depuis VS Code (Windows)
via **Remote-SSH + Dev Containers** sur `srv-m720q` (Debian 13, Docker rootless par
utilisateur). L'hôte est préparé par le rôle `devhost` du dépôt homelab ; ce dépôt
ne contient que les images, les modèles et les scripts. Il se clone dans `~/dev/envs`.

```
images/<toolchain>/Dockerfile        # devenv-<toolchain>:latest
templates/<toolchain>/devcontainer.json
scripts/build.sh, scripts/devinit.sh
Makefile
```

## Utilisation avec VS Code

### 1. Une fois, sur le poste Windows

- Installer VS Code et les extensions **Remote - SSH** et **Dev Containers**.
- Démarrer l'agent SSH Windows et y charger ta clé (PowerShell administrateur pour la
  première commande) :

  ```powershell
  Set-Service ssh-agent -StartupType Automatic; Start-Service ssh-agent
  ssh-add $env:USERPROFILE\.ssh\id_ed25519     # ta clé ; vérifier avec : ssh-add -l
  ```

- Déclarer le m720q dans `%USERPROFILE%\.ssh\config`. `ForwardAgent yes` est
  indispensable : c'est lui qui donne accès à tes clés dans le conteneur, sans qu'aucune
  clé privée ne soit copiée sur le serveur.

  ```
  # Depuis le LAN
  Host srv-m720q
      HostName 192.168.83.41
      User julien
      ForwardAgent yes

  # Depuis l'extérieur, par le bastion
  Host bastion
      HostName spikeju.ddns.net
      Port 48222
      User julien
      ForwardAgent yes

  Host srv-m720q-wan
      HostName 192.168.83.41
      User julien
      ProxyJump bastion
      ForwardAgent yes
  ```

### 2. Sur le m720q (fait par Ansible)

Le rôle `devhost` du dépôt homelab clone ce dépôt dans `~/dev/envs` et le met à jour
(sans écraser de modification locale). Il ne construit pas les images : dans un
terminal VS Code connecté en Remote-SSH,

```bash
cd ~/dev/envs && make build sys     # construit devenv-sys:latest dans ton Docker rootless
```

Reconstruire une image (`make build <toolchain>`) quand son Dockerfile change.

### 3. Pour chaque projet

```bash
git clone git@github.com:jnicol31/homelab.git ~/dev/projects/homelab   # avec ta clé (agent relayé), pour pouvoir pousser
~/dev/envs/scripts/devinit.sh homelab sys
```

`devinit.sh <projet> <toolchain>` copie le modèle dans
`~/dev/projects/<projet>/.devcontainer/devcontainer.json` et refuse d'écraser un
fichier existant. Le modèle peut ensuite être adapté au projet (limites cpu/mémoire,
extensions, montages).

### 4. Ouvrir le projet dans le conteneur

1. VS Code : `F1` → **Remote-SSH: Connect to Host…** → `srv-m720q` (ou `srv-m720q-wan`).
2. **File → Open Folder** → `/home/julien/dev/projects/homelab`.
3. `F1` → **Dev Containers: Reopen in Container**.

Le terminal VS Code est alors dans le conteneur : le code est sur `/workspace`, les
sorties de build sur `/build`, les caches viennent de `~/dev/cache/`.

## `sys` : contrôleur Ansible

L'image `devenv-sys` sert de machine d'administration : Ansible (`ansible-core`
2.20 dans un venv, collections `ansible.posix`, `community.docker`,
`community.general`), `ansible-lint`, `yamllint`, `shellcheck`, `shfmt`, `make`,
`git`, `jq`, `rsync`, `sops`, `age` et le client SSH.

Dans le conteneur ouvert sur le projet homelab :

```bash
ssh-add -l                                            # ta clé doit apparaître (agent relayé)
ssh julien@192.168.83.44 true                         # une fois par hôte : accepte l'empreinte (known_hosts)
ssh julien@192.168.83.41 true
make check                                            # ansible-lint + shellcheck
ansible-playbook -i ansible/inventory/hosts.yml ansible/site.yml --limit srv-m720q --check --diff -K
```

- **Réseau :** le conteneur tourne sur le m720q, donc sur le LAN, quelle que soit la
  façon dont VS Code atteint le m720q (LAN ou bastion). On utilise
  `ansible/inventory/hosts.yml` (accès direct). `remote.yml` (saut par le bastion)
  reste possible mais inutile depuis le LAN. L'utilisateur de connexion est celui de la
  session SSH sur le m720q (`ANSIBLE_REMOTE_USER`).
- **Clés SSH :** aucune clé privée dans l'image ni montée. Seul `known_hosts` est
  conservé (`~/dev/cache/ssh` sur `/root/.ssh`).
- **Clé age admin :** jamais dans le conteneur. Les playbooks n'en ont pas besoin
  (chaque hôte déchiffre avec sa propre clé) ; le rechiffrement des secrets se fait
  depuis le poste de l'administrateur.
- Les playbooks se lancent comme d'habitude : `-K` pour le mot de passe sudo, et
  l'accord explicite avant tout run réel sur un hôte.

### Dépannage

| Symptôme | Cause probable |
| --- | --- |
| `ssh-add -l` : « Could not open a connection to your authentication agent » | `ForwardAgent yes` absent du `config` Windows, ou service `ssh-agent` arrêté. |
| `Permission denied (publickey)` vers un hôte | Clé non chargée (`ssh-add` sur Windows), ou utilisateur non fourni (`ANSIBLE_REMOTE_USER` vide : lancer avec `-u julien`). |
| `Host key verification failed` | Empreinte jamais acceptée : `ssh <hôte> true` à la main une fois. |
| « Cannot connect to the Docker daemon » au lancement du conteneur | Service Docker rootless arrêté : `systemctl --user start docker` sur le m720q. |
| `docker.sock` introuvable (montage) | Session SSH sans `XDG_RUNTIME_DIR` : ouvrir une vraie session (Remote-SSH, pas `ssh -T`). |
| Image `devenv-sys:latest` introuvable | `make build sys` non fait sur le m720q. |

## Makefile

```bash
make build            # toutes les images (ou : make build sys)
make push sys         # envoie devenv-sys sur HOST (srv-m720q par défaut)
make check            # hadolint, shellcheck + shfmt, JSON valides
```

En usage normal, le dépôt est cloné sur le m720q (`~/dev/envs`) et `make build` y
construit directement dans le Docker rootless de l'utilisateur : `make push` ne sert
que si l'on construit ailleurs (`docker save | ssh <hôte> docker load`, sans registre).
