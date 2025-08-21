## Tech Stack Overview

This project provides a complete email platform composed of a Go-based core service, a Vue 3 admin frontend, and a production-grade mail stack (Postfix, Dovecot, Rspamd, Roundcube), orchestrated via Docker Compose.

### Backend (Go)

- **Language/Runtime**: Go 1.22 (toolchain 1.23.2)
- **Framework**: GoFrame v2 (`github.com/gogf/gf/v2`)
- **Persistence**:
  - **PostgreSQL** via `gf/contrib/drivers/pgsql/v2`
  - **Redis** via `gf/contrib/nosql/redis/v2`
- **Auth/Crypto**: `golang-jwt/jwt/v5`, `golang.org/x/crypto`
- **Mail/Infra Integrations**:
  - Docker API: `github.com/docker/docker`
  - ACME/Let’s Encrypt: `github.com/go-acme/lego/v4`
  - Excel export: `github.com/xuri/excelize/v2`
- **Concurrency/Utilities**: `github.com/panjf2000/ants/v2`, `github.com/google/uuid`, `github.com/fsnotify/fsnotify`
- **AI Integrations**: `github.com/sashabaranov/go-openai`, `github.com/pkoukk/tiktoken-go`
- **Other**: CAPTCHA (`github.com/mojocn/base64Captcha`), YAML (`gopkg.in/yaml.v3`)

Key paths:
- `core/` (Go sources)
- `core/go.mod` (module: `billionmail-core`)

### Frontend (Web)

- **Framework**: Vue 3 + TypeScript
- **Build tool**: Rsbuild (`@rsbuild/core`) with Vue, Vue JSX, Sass, ESLint plugins
- **State/Router/i18n**: Pinia, Vue Router, `vue-i18n` v11
- **Styling**: SCSS, UnoCSS (preset-uno, icons, attributify)
- **UI/Charts/Editor**: Naive UI, ECharts, Monaco Editor
- **HTTP/Utils**: Axios, date-fns, lodash-es, markdown (marked/markdown-it), highlight/prism
- **Lint/Format**: ESLint 9 + Prettier 3

Key paths:
- `core/frontend/` (Vue app)
- `core/frontend/src/index.ts` (app entry)
- `core/frontend/eslint.config.mjs`
- `core/frontend/package.json`

### Mail Stack (Services)

Provisioned via Docker Compose (`docker-compose.yml`):

- **PostgreSQL**: `postgres:17.4-alpine`
- **Redis**: `redis:7.4.2-alpine`
- **Rspamd**: `billionmail/rspamd:1.2` (spam filtering)
- **Dovecot**: `billionmail/dovecot:1.5` (IMAP/POP)
- **Postfix**: `billionmail/postfix:1.6` (SMTP)
- **Roundcube**: `roundcube/roundcubemail:1.6.10-fpm-alpine` (webmail)
- **Core service**: `billionmail/core:4.2.1` (supervisor, rsyslog, fail2ban)

Dockerfiles:
- `Dockerfiles/core/Dockerfile` (Alpine-based, copies Go-built binary and assets)
- `Dockerfiles/postfix/Dockerfile` (Debian bookworm-slim)
- Additional Dockerfiles under `Dockerfiles/dovecot` and `Dockerfiles/rspamd`

### Orchestration & Runtime

- **Docker Compose** with a custom bridge network `br-billionmail` (subnet via `${IPV4_NETWORK}`)
- **Volumes**: bind mounts for configs, logs, SSL certs, data directories
- **Inter-service**: Docker socket mounted into the core for management operations

### Configuration & Security

- **Mail configs**: `conf/postfix`, `conf/dovecot`, `conf/rspamd`
- **Webmail/PHP-FPM**: `conf/webmail`, `conf/php`
- **Fail2ban**: filters and jails via `conf/core/fail2ban/*` mounted into core
- **i18n (server/client)**: `core/languages`, `core/frontend/src/i18n`

### Exposed Ports (defaults via environment)

- **Core UI/API**: 80 (HTTP), 443 (HTTPS)
- **SMTP**: 25, 465 (SMTPS), 587 (Submission)
- **IMAP/POP**: 143/993 (IMAP/IMAPS), 110/995 (POP/POPS)
- **PostgreSQL**: host `${SQL_PORT:-127.0.0.1:25432}` → container `5432`
- **Redis**: host `${REDIS_PORT:-127.0.0.1:26379}` → container `6379`

### Primary Languages

- Go, TypeScript/JavaScript, SCSS, Shell (plus PHP config for Roundcube)

### Scripts & Tooling

- Frontend scripts: `rsbuild dev|build|preview`, ESLint, Prettier
- Backend build scripts under `core/` (Go modules) and image build under `Dockerfiles/*`

### Notes

- No explicit frontend test framework was observed in the current configuration.
- Ensure environment variables in `.env` are set for database, Redis, and hostnames before deployment.


