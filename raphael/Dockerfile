FROM ollama/ollama:latest


RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y python3 curl ffmpeg zstd

COPY . /app
WORKDIR /app

RUN chmod +x ./entry.sh

EXPOSE 11434

ENTRYPOINT ["/bin/bash", "./entry.sh"]