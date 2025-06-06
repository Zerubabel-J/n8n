# Use the official Docker Hub image (RECOMMENDED)
FROM n8nio/n8n

# Set timezone and port
ENV N8N_PORT=5678
ENV GENERIC_TIMEZONE=UTC

# Expose port used by n8n
EXPOSE 5678

# Start n8n
CMD ["n8n"]
