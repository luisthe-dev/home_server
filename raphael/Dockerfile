FROM ollama/ollama:latest

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 curl ffmpeg zstd jq \
    && rm -rf /var/lib/apt/lists/*

COPY . /app
WORKDIR /app

RUN chmod +x ./entry.sh

EXPOSE 11434

ENTRYPOINT ["/bin/bash", "./entry.sh"]