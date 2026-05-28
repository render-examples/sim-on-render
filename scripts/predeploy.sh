#!/usr/bin/env sh
set -eu

log() {
  printf '[sim-predeploy] %s\n' "$1"
}

log "starting"
log "DATABASE_URL is ${DATABASE_URL:+set}"

cd /migrations/packages/db

log "working directory: $(pwd)"
log "enabling pgvector"
bun -e 'import postgres from "postgres"; const sql = postgres(process.env.DATABASE_URL); await sql.unsafe("CREATE EXTENSION IF NOT EXISTS vector"); await sql.end();'

log "running migrations"
bun run db:migrate
log "complete"
