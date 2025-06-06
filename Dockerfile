# Use the official n8n Docker image
FROM docker.n8n.io/n8nio/n8n

# Set environment variables
ENV N8N_PORT=5678
ENV GENERIC_TIMEZONE="UTC"

# Expose the port that n8n listens on
EXPOSE 5678

# Run n8n
CMD ["n8n"]
