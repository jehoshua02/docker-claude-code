# docker-claude-code

A vanilla Claude Code Docker image with security hardening. No plugins, no opinionated defaults — just Claude Code in a locked-down container. You bring your own workspace, settings, and plugins via volume mounts.

**Image:** `jehoshua02/claude-code` on DockerHub

## What's in the image

- `debian:bookworm-slim` base
- `git`, `curl`, `bash`, `openssh-client`, `ca-certificates`
- Claude Code CLI (installed via official installer)
- Non-root `claude` user (uid 1000)
- Pre-populated `known_hosts` for GitHub, GitLab, Bitbucket
- Entrypoint that handles SSH key setup and git identity

## Authentication

Two options:

**Option A: API key** — set `ANTHROPIC_API_KEY` as an environment variable.

**Option B: OAuth (Pro/Max subscription)** — mount your host's `~/.claude` to `/home/claude/.claude` and your existing credentials just work. Or mount any directory there and run `claude auth login` inside the container on first run.

## Quick start

With API key:
```bash
docker run --rm -it \
  -e ANTHROPIC_API_KEY=sk-ant-... \
  -v ./workspace:/workspace \
  -v ~/.claude:/home/claude/.claude \
  jehoshua02/claude-code:latest
```

With OAuth (using host's ~/.claude):
```bash
docker run --rm -it \
  -v ./workspace:/workspace \
  -v ~/.claude:/home/claude/.claude \
  jehoshua02/claude-code:latest
```

## Recommended: security-hardened run

```bash
docker run --rm -it \
  -e GIT_USER_NAME="Your Name" \
  -e GIT_USER_EMAIL="you@example.com" \
  -v ./workspace:/workspace \
  -v ~/.claude:/home/claude/.claude \
  --cap-drop ALL \
  --security-opt no-new-privileges \
  --read-only \
  --tmpfs /tmp:uid=1000,gid=1000 \
  --tmpfs /home/claude/.ssh:uid=1000,gid=1000 \
  --memory 4g \
  --cpus 2 \
  jehoshua02/claude-code:latest
```

Add `-e ANTHROPIC_API_KEY=sk-ant-...` if using an API key, or ensure OAuth credentials exist in the mounted volume.

### What each flag does

| Flag | Purpose |
|------|---------|
| `--cap-drop ALL` | Drop all Linux capabilities. Claude doesn't need any. |
| `--security-opt no-new-privileges` | Block privilege escalation via setuid/setgid. |
| `--read-only` | Root filesystem is read-only. Writes only to volumes and tmpfs. |
| `--tmpfs /tmp:uid=1000,gid=1000` | Writable scratch space (lost on container stop). |
| `--tmpfs /home/claude/.ssh:uid=1000,gid=1000` | Entrypoint writes SSH config here at startup. |
| `--memory 4g` | Cap memory usage. Adjust to your needs. |
| `--cpus 2` | Cap CPU usage. Adjust to your needs. |

## Docker Compose

See `compose.example.yml` for a fully commented reference. Copy and adapt:

```bash
cp compose.example.yml compose.yml
# edit compose.yml
docker compose run --rm claude
```

## Volume mounts

| Container path | Purpose | Example host path |
|---------------|---------|-------------------|
| `/workspace` | Your project files. Claude reads and writes here. | `~/projects/my-app` |
| `/home/claude/.claude` | Persisted state: settings, history, plugins, OAuth tokens. | `~/.claude` |

## Environment variables

| Variable | Required | Purpose |
|----------|----------|---------|
| `ANTHROPIC_API_KEY` | Yes (unless OAuth) | API key for Claude. |
| `GIT_USER_NAME` | No | Git author name for commits. |
| `GIT_USER_EMAIL` | No | Git author email for commits. |

## SSH key (optional)

If Claude needs SSH access (e.g. private git repos), provide your key as a Docker secret. This is the most secure method — the key is never baked into image layers or visible in `docker inspect`.

With Docker Compose (see `compose.example.yml`):
```yaml
secrets:
  ssh_private_key:
    file: ./ssh_key
```

With `docker run`:
```bash
docker run --rm -it \
  ... \
  --secret id=ssh_private_key,src=./ssh_key \
  jehoshua02/claude-code:latest
```

Note: `--secret` requires BuildKit or Swarm mode. For simple setups, you can bind-mount the key directly:
```bash
-v ~/.ssh/id_rsa:/run/secrets/ssh_private_key:ro
```

The entrypoint checks `/run/secrets/ssh_private_key` at startup and copies it into `~/.ssh/id_rsa` with locked-down permissions.

## Plugins and settings

This image ships with no plugins and no default settings. Mount a directory to `/home/claude/.claude` (e.g. your host's `~/.claude`) and:

- Install plugins from inside a running session: `claude plugin install <name>`
- Settings, plugins, and history persist across container restarts

## Passing arguments to Claude

All arguments are forwarded to the `claude` CLI:

```bash
# One-shot prompt
docker run --rm \
  -e ANTHROPIC_API_KEY=sk-ant-... \
  -v ./workspace:/workspace \
  jehoshua02/claude-code:latest \
  -p "Review the code and suggest improvements"

# With specific allowed tools
docker run --rm -it \
  ... \
  jehoshua02/claude-code:latest \
  --allowedTools "Read,Write,Bash"
```

---

## Developer guide

### Prerequisites

- Docker
- DockerHub account with push access to `jehoshua02/claude-code`

### Build

```bash
./build.sh 1.0.0
```

Builds and tags:
- `jehoshua02/claude-code:1.0.0`
- `jehoshua02/claude-code:latest`

### Build and push

```bash
docker login
./build.sh 1.0.0 --push
```

### Git tag convention

After a successful push, tag the commit:

```bash
git tag v1.0.0
git push origin v1.0.0
```

### Versioning

Semver. Bump when:
- **Patch** — dependency updates, doc fixes, entrypoint bugfixes
- **Minor** — new features in the entrypoint, added system packages
- **Major** — breaking changes to mount paths, env vars, or entrypoint behavior
