#!/usr/bin/env sh
set -eu

cd /migrations/packages/db

bun -e 'import postgres from "postgres"; const sql = postgres(process.env.DATABASE_URL); await sql.unsafe("CREATE EXTENSION IF NOT EXISTS vector"); await sql.end();'
bun run db:migrate
