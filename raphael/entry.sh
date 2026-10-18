#!/bin/bash
set -e

# Start Ollama daemon in background
ollama serve &
OLLAMA_PID=$!

# Graceful shutdown handler
cleanup() {
    echo "Stopping Ollama daemon (PID: $OLLAMA_PID)..."
    kill -TERM "$OLLAMA_PID" 2>/dev/null || true
    wait "$OLLAMA_PID" 2>/dev/null || true
    exit 0
}
trap cleanup SIGINT SIGTERM

echo "Waiting for Ollama engine to initialize..."
until curl -s http://127.0.0.1:11434/api/tags > /dev/null 2>&1; do
    sleep 2
done
echo "AI engine is online."

hash_cache_file="/app/hash_cache.json"

pull_model() {
    local model_name="$1"
    [ -z "$model_name" ] && return 0

    if ollama list | awk '{print $1}' | grep -E "(^|/)${model_name}(:latest)?$" > /dev/null 2>&1; then
        echo "✅ Model $model_name already exists. Skipping..."
    else
        echo "⬇️  Downloading $model_name..."
        if ollama pull "$model_name"; then
            echo "✅ Successfully pulled $model_name"
        else
            echo "⚠️  Failed to pull $model_name. Continuing..."
        fi
    fi
}

build_persona(){
    local model_file="$1"
    local model_alias="$2"

    [ ! -f "$model_file" ] && return 0
    [ -z "$model_alias" ] && return 0

    # Initialize hash_cache file if missing or invalid JSON
    if [ ! -f "$hash_cache_file" ] || ! jq . "$hash_cache_file" >/dev/null 2>&1; then
        echo '{}' > "$hash_cache_file"
        echo "Hash cache initialized..."
    fi

    local persona_current_hash
    persona_current_hash=$(md5sum "$model_file" | awk '{print $1}')
    local persona_cached_hash
    persona_cached_hash=$(jq -r --arg a "$model_alias" '.[$a] // empty' "$hash_cache_file")

    if [ -n "$persona_cached_hash" ] && [ "$persona_cached_hash" = "$persona_current_hash" ]; then
        echo "✅ $model_alias Persona has not changed. Skipping..."
    else
        echo "🔨 $model_alias Persona updated or new. Building..."
        if ollama create "$model_alias" -f "$model_file"; then
            local temp_file
            temp_file=$(mktemp /tmp/hash_cache.XXXXXX.json)
            jq --arg alias "$model_alias" --arg hash "$persona_current_hash" \
               '. + {($alias): $hash}' "$hash_cache_file" > "$temp_file" && mv "$temp_file" "$hash_cache_file"
            echo "✅ $model_alias Persona ready."
        else
            echo "❌ Failed to build $model_alias persona."
        fi
    fi
}

echo "Resolving models to pull..."

models_to_pull=()

if [ -n "$OLLAMA_MODELS" ]; then
    echo "Loading models from OLLAMA_MODELS environment variable..."
    IFS=',' read -ra RAW_MODELS <<< "$OLLAMA_MODELS"
    for item in "${RAW_MODELS[@]}"; do
        trimmed=$(echo "$item" | xargs)
        [ -n "$trimmed" ] && models_to_pull+=("$trimmed")
    done
elif [ -f "/app/models.txt" ]; then
    echo "Loading models from /app/models.txt..."
    while IFS= read -r line || [ -n "$line" ]; do
        trimmed=$(echo "$line" | sed 's/#.*//' | xargs)
        [ -n "$trimmed" ] && models_to_pull+=("$trimmed")
    done < "/app/models.txt"
else
    echo "Using default fallback model list..."
    models_to_pull=("llama3.1" "gemma4" "deepseek-r1" "qwen3.5" "qwen2.5-coder")
fi

echo "Pulling models: ${models_to_pull[*]} ..."
for model in "${models_to_pull[@]}"; do
    pull_model "$model"
done
echo "All configured models checked!"

echo "Building Personas ..."
models_dir="/app/my_models"

if [ -d "$models_dir" ]; then
    shopt -s nullglob
    for Modelfile in "$models_dir"/*; do
        [ -f "$Modelfile" ] || continue
        base_name=$(basename "$Modelfile")

        # Parse alias from Modelfile.<alias> or <alias>.Modelfile
        if [[ "$base_name" == Modelfile.* ]]; then
            model_alias="${base_name#Modelfile.}"
        elif [[ "$base_name" == *.Modelfile ]]; then
            model_alias="${base_name%.Modelfile}"
        else
            model_alias="${base_name#*.}"
        fi

        [ -n "$model_alias" ] && build_persona "$Modelfile" "$model_alias"
    done
    shopt -u nullglob
else
    echo "Directory $models_dir not found. Skipping persona build."
fi

echo "Personas Booted!!!"
echo "AI standalone server is online."

wait "$OLLAMA_PID"