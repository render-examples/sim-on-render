FROM ghcr.io/simstudioai/migrations:latest AS migrations

FROM ghcr.io/simstudioai/simstudio:latest

USER root

# The upstream app image does not include the migration workspace.
# Copy it into the runtime image so Render can run preDeployCommand.
COPY --from=migrations --chown=nextjs:nodejs /app /migrations

USER nextjs
