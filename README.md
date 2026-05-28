# Sim on Render

> Deploy Sim with its app, realtime socket server, and Postgres database on Render.

[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy-template/api/github/start?template_repo=sim-on-render)

This template deploys the open-source [Sim](https://github.com/simstudioai/sim) platform using the upstream container images and a Render-managed PostgreSQL database. It is for teams that want a self-hosted Sim workspace without running Docker Compose, managing Postgres, or copying service URLs between containers.

## Table of Contents

- [Why Deploy Sim on Render](#why-deploy-sim-on-render)
- [Use Cases](#use-cases)
- [What Gets Deployed](#what-gets-deployed)
- [Quickstart](#quickstart)
- [Configuration](#configuration)
- [Cost Breakdown](#cost-breakdown)
- [Customization](#customization)
- [Operations](#operations)
- [Upgrading](#upgrading)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)
- [Security](#security)
- [Caveats and Limitations](#caveats-and-limitations)
- [Credits and License](#credits-and-license)

## Why Deploy Sim on Render

- **Managed Postgres**: Render provisions the database and wires `DATABASE_URL`.
- **Upstream images**: The template follows Sim's Docker-based production path.
- **Separate realtime service**: Socket.IO runs as its own web service with health checks.
- **Migration hook**: Database migrations run before the app starts each deploy.
- **Generated shared secrets**: Render creates the auth and internal API secrets.

## Use Cases

What you can build with this template:

- **Internal agent workflow builder**: Give a team a self-hosted canvas for AI automations.
- **RAG prototypes**: Upload documents and test knowledge-backed workflows.
- **Ops automation**: Connect tools, APIs, and models in a private workspace.
- **Self-hosted evaluation lab**: Test Sim before committing to a larger deployment.

## What Gets Deployed

```mermaid
flowchart LR
  user["Browser user"] --> app["simstudio web service"]
  user --> realtime["simstudio-realtime web service"]
  app --> db[("simstudio-db Postgres")]
  app --> redis[("simstudio-redis Key Value")]
  realtime --> db
  realtime --> redis
  app --> realtime
```

| Resource | Type | Plan | Purpose |
|----------|------|------|---------|
| `simstudio` | Web service, Docker wrapper | `standard` | Runs the Sim Next.js app and migrations |
| `simstudio-realtime` | Web service, image | `starter` | Runs the Socket.IO realtime server |
| `simstudio-redis` | Key Value | `starter` | Stores realtime and Copilot stream state |
| `simstudio-db` | PostgreSQL 18 | `basic-256mb` | Stores users, workspaces, workflows, and knowledge metadata |

Region: `oregon`. Change every `region` value in `render.yaml` before the first deploy if you need a different region. Database region is immutable after creation.

## Quickstart

1. Click **[Deploy to Render](https://render.com/deploy-template/api/github/start?template_repo=sim-on-render)**.
2. Choose the GitHub account or organization that should receive the fork.
3. Generate two 64-character hex strings with `openssl rand -hex 32`, then paste one into `ENCRYPTION_KEY` and the other into `API_ENCRYPTION_KEY`.
4. Apply the Blueprint and wait for the first image pull, database migration, and service deploys. The first deploy usually takes 5 to 10 minutes.
5. Optionally add `COPILOT_API_KEY` after deploy if you created one at [sim.ai](https://sim.ai).
6. Open the `simstudio` `*.onrender.com` URL when the service is live.

## Configuration

### Required Secrets

You set these in the Render Dashboard during the Blueprint Apply step.

| Env var | What it's for | How to get it |
|---------|---------------|---------------|
| `ENCRYPTION_KEY` | Encrypts stored workflow credentials and other sensitive values | Run `openssl rand -hex 32` |
| `API_ENCRYPTION_KEY` | Encrypts API keys stored by Sim | Run `openssl rand -hex 32` |
| `OPENAI_API_KEY` | Optional OpenAI key for agent blocks and embeddings | Create an OpenAI API key, or leave blank |
| `ANTHROPIC_API_KEY_1` | Optional Anthropic Claude key for agent blocks | Create an Anthropic API key, or leave blank |
| `GEMINI_API_KEY_1` | Optional Google Gemini key for agent blocks | Create a Gemini API key, or leave blank |
| `MISTRAL_API_KEY` | Optional Mistral key for OCR and agent blocks | Create a Mistral API key, or leave blank |

`ENCRYPTION_KEY` and `API_ENCRYPTION_KEY` must be 64-character hex strings. Do not use Render's generated secret format for these keys because Sim expects hex. The provider keys are optional; leave unused providers blank.

Generate them locally before you apply the Blueprint:

```bash
openssl rand -hex 32 # use for ENCRYPTION_KEY
openssl rand -hex 32 # use for API_ENCRYPTION_KEY
```

Each command prints a different 64-character value. Paste the first value into `ENCRYPTION_KEY` and the second value into `API_ENCRYPTION_KEY` in the Render Blueprint Apply form.

### Auto-Generated Secrets

Render generates these on first deploy and stores them as service env vars. Do not rotate them later unless you understand the data they protect.

| Env var | Purpose |
|---------|---------|
| `BETTER_AUTH_SECRET` | Signs Better Auth sessions and tokens |
| `INTERNAL_API_SECRET` | Authenticates internal calls between the app and realtime service |

### Wired Automatically

The Blueprint wires these values from other Render resources. You do not type them.

| Env var | Source |
|---------|--------|
| `DATABASE_URL` | `simstudio-db.connectionString` |
| `REDIS_URL` | `simstudio-redis.connectionString` |
| `NEXT_PUBLIC_APP_URL` | `simstudio.RENDER_EXTERNAL_URL` |
| `BETTER_AUTH_URL` | `simstudio.RENDER_EXTERNAL_URL` |
| `NEXT_PUBLIC_SOCKET_URL` | `simstudio-realtime.RENDER_EXTERNAL_URL` |
| `SOCKET_SERVER_URL` | `simstudio-realtime.RENDER_EXTERNAL_URL` |
| `ALLOWED_ORIGINS` | `simstudio.RENDER_EXTERNAL_URL` |

### Optional Tweaks

Common things people change after deploying:

| Env var | Default | What it does |
|---------|---------|--------------|
| `COPILOT_API_KEY` | Empty | Enables Sim-managed Copilot features for self-hosted installs |
| `ADMISSION_GATE_MAX_INFLIGHT` | `500` | Caps concurrent workflow admissions in the app |
| `DISABLE_AUTH` | Empty | Bypasses authentication for private, trusted deployments |
| `TRUSTED_ORIGINS` | Empty | Adds extra auth origins, such as custom domain aliases |
| `OLLAMA_URL` | Empty | Points Sim at an Ollama server for local models |
| `REDIS_URL` | Wired automatically | Enables realtime and Copilot stream state |

Add optional env vars after the first deploy from the service's **Environment** page.

### AI provider keys

Add model provider keys to the `simstudio` service after deploy. Sim uses these keys for agent blocks, knowledge-base embeddings, and provider-specific model access.

| Env var | Provider |
|---------|----------|
| `OPENAI_API_KEY` or `OPENAI_API_KEY_1` | OpenAI |
| `ANTHROPIC_API_KEY_1` | Anthropic Claude |
| `GEMINI_API_KEY_1` | Google Gemini |
| `MISTRAL_API_KEY` | Mistral |
| `OLLAMA_URL` | Ollama |
| `VLLM_BASE_URL` | vLLM or another OpenAI-compatible server |

For multiple OpenAI, Anthropic, or Gemini keys, add numbered suffixes such as `_1`, `_2`, and `_3`. See Sim's [environment variables](https://docs.sim.ai/self-hosting/environment-variables) reference for the full provider list.

Full upstream configuration reference: [Sim self-hosting docs](https://docs.sim.ai/self-hosting/docker).

## Cost Breakdown

| Resource | Plan | Monthly cost |
|----------|------|--------------|
| `simstudio` | `standard` | $25 |
| `simstudio-realtime` | `starter` | $7 |
| `simstudio-redis` | `starter` | $10 |
| `simstudio-db` | `basic-256mb` | $6 |
| **Total** | | **$48** |

Render's full pricing: [render.com/pricing](https://render.com/pricing).

**Cheaper:** You can try `starter` for `simstudio`, but expect memory pressure on larger workflows. Do not use the free plan for this template.

**Scale up:** Increase the `simstudio` plan first. Scale Key Value if Copilot or realtime traffic grows.

## Customization

### Pin the Upstream Version

The template defaults to the upstream `latest` image tags. Pin tags before production use:

```yaml
# render.yaml
image:
  url: ghcr.io/simstudioai/realtime:v0.6.92
```

For the app wrapper, pin both base images in `Dockerfile`:

```dockerfile
FROM ghcr.io/simstudioai/migrations:v0.6.92 AS migrations
FROM ghcr.io/simstudioai/simstudio:v0.6.92
```

### Add a Custom Domain

In the Render Dashboard, open `simstudio` → **Settings** → **Custom Domains** → **Add**. Render issues TLS automatically. After the domain is active, update `NEXT_PUBLIC_APP_URL`, `BETTER_AUTH_URL`, `ALLOWED_ORIGINS`, and any OAuth callback URLs to use the custom domain.

### Add Redis for Realtime Scaling

The default realtime service uses in-memory room state and should stay at one instance. To scale it horizontally, add a Render Key Value service and wire `REDIS_URL` into `simstudio-realtime`.

```yaml
- type: keyvalue
  name: simstudio-redis
  plan: starter
  region: oregon
  maxmemoryPolicy: noeviction
```

### Enable Third-Party OAuth

Add provider credentials as service env vars on `simstudio`, such as `GITHUB_CLIENT_ID`, `GITHUB_CLIENT_SECRET`, `GOOGLE_CLIENT_ID`, and `GOOGLE_CLIENT_SECRET`. Update provider callback URLs to match your Render or custom domain.

### Enable PR Previews

This template sets `previews.generation: off` because gallery deployments are one-shot forks. If you maintain your fork as an app repo, change it to `manual` or `automatic` after you understand the extra database cost.

## Operations

### Backups

Render backs up the managed PostgreSQL database according to the database plan. Key Value is used for stream and realtime state, not as the source of truth for workflows.

### Monitoring

Use the Render Dashboard metrics and logs for both web services. The app health check is `/api/health`; the realtime health check is `/health`.

### Scaling

Scale `simstudio` vertically first. Key Value is already wired so `simstudio-realtime` can use Redis-backed room state.

### Logs

In the Render Dashboard, open a service and choose **Logs**. CLI: `render logs --resources srv-your-service-id --tail`.

## Upgrading

### Pick Up Upstream Releases

Watch [Sim releases](https://github.com/simstudioai/sim/releases). If you use `latest`, trigger a manual deploy to pull the newest upstream images. If you pin tags, update `Dockerfile` and `render.yaml` together, then deploy.

### Breaking-Change Migrations

Read the upstream release notes before upgrading across major versions. The app service runs `bun run db:migrate` before each deploy, but application-level migration notes still matter for auth, integrations, and feature flags.

## Troubleshooting

### Deploy Fails During Image Pull

The GHCR image tag might be unavailable, mistyped, or temporarily unreachable. Confirm the tag exists in [the upstream packages](https://github.com/simstudioai/sim/pkgs/container/simstudio), then redeploy.

### Service Starts but Health Check Fails

Check the service logs first. Common causes are a missing 64-character `ENCRYPTION_KEY`, a failed database migration, or an app plan that is too small for startup memory.

### Migration Fails on `vector` Type or Extension

Sim uses pgvector for knowledge-base embeddings. The pre-deploy command runs `CREATE EXTENSION IF NOT EXISTS vector` before migrations. If you created the database outside this template, enable pgvector manually with `CREATE EXTENSION IF NOT EXISTS vector;`, then redeploy.

### `ENCRYPTION_KEY must be set to a 64-character hex string`

Replace `ENCRYPTION_KEY` with the output of `openssl rand -hex 32`, then redeploy. Do not rotate this value after users store credentials unless you are prepared to re-encrypt existing data.

### Browser Cannot Connect to Realtime

Check that `NEXT_PUBLIC_SOCKET_URL` on `simstudio` points to the `simstudio-realtime` external URL and that `ALLOWED_ORIGINS` on `simstudio-realtime` points to the app external URL or custom domain.

### Workflows Work Locally but Fail on Render

Check whether the workflow depends on a provider API key or a local-only endpoint such as Ollama. Add provider keys as env vars or point `OLLAMA_URL` at a reachable service.

### Anything Else

- Service logs: Dashboard → service → **Logs**
- Deploy logs: Dashboard → service → **Events** → failed deploy
- Template bugs: open an issue in this template repo
- Application bugs: open an issue in [simstudioai/sim](https://github.com/simstudioai/sim/issues)

## FAQ

### Can I Run This on Render's Free Plan?

No. Sim is a multi-service app with Postgres and a large Node runtime. Use the default paid plans first, then downsize only after observing memory and CPU metrics.

### Why Is There a Dockerfile if the Template Uses Upstream Images?

Render's `preDeployCommand` runs inside the app service image. The upstream app image does not include the migration workspace, so this template builds a small wrapper that copies migration files from `ghcr.io/simstudioai/migrations`.

### Do I Need a Copilot API Key?

Only if you want Sim-managed Copilot on a self-hosted instance. You can deploy without it and add `COPILOT_API_KEY` later.

### Can I Use a Custom Domain?

Yes. Add the custom domain to `simstudio`, then update the public app URL and auth URL env vars to match it. Also update OAuth provider callback URLs.

### Can I Migrate Existing Sim Data?

Yes, if you can export from your current PostgreSQL database and restore into `simstudio-db`. Stop writes during the migration, restore the dump, then redeploy both services.

### What Happens if I Delete the Database?

You lose Sim data after the database and its retained backups are gone. Export first if you need to keep workflows, users, and workspace data.

## Security

- **Encryption at rest:** Render-managed PostgreSQL is encrypted at rest. Sim also encrypts stored secrets with `ENCRYPTION_KEY` and API keys with `API_ENCRYPTION_KEY`.
- **Encryption in transit:** Render terminates TLS for `*.onrender.com` and custom domains. App-to-database traffic uses Render's private network connection string.
- **Network exposure:** Both web services are public because browsers connect to the app and Socket.IO endpoint. Internal POST routes require `INTERNAL_API_SECRET`.
- **Secret rotation:** Rotate `COPILOT_API_KEY` when needed. Do not rotate `ENCRYPTION_KEY`, `API_ENCRYPTION_KEY`, `BETTER_AUTH_SECRET`, or `INTERNAL_API_SECRET` without planning for sessions and encrypted data.
- **Reporting vulnerabilities:** Template issues belong in this repo. Application vulnerabilities belong in the upstream [Sim security policy](https://github.com/simstudioai/sim/security).

## Caveats and Limitations

- Key Value is required for Copilot stream durability and realtime state.
- The template uses upstream `latest` tags by default. Pin tags for production change control.
- The app plan starts at `standard`. Downgrading can produce startup OOMs or health check failures.
- `ENCRYPTION_KEY` and `API_ENCRYPTION_KEY` are manual because Sim requires 64-character hex strings.
- The first deploy pulls large images and runs migrations, so it is slower than later deploys.
- Postgres region and major version are immutable after creation.

## Credits and License

- **Upstream:** [simstudioai/sim](https://github.com/simstudioai/sim) under the Apache License 2.0
- **Render template:** MIT, see [LICENSE](./LICENSE)
- **Template maintainer:** [render-examples](https://github.com/render-examples)

If this template helps you, give the upstream Sim repo a star.
