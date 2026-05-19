#!/bin/sh

ollama serve &

echo "Waiting for AI engine to initialize..."
until curl -s http://127.0.0.1:11434/api/tags > /dev/null; do
  sleep 5
done

echo "Verifying local models..."

hash_cache_file="hash_cache.json"

pull_model() {
    model_name=$1
    if ollama list | grep -q "$model_name"; then
        echo "✅ Model $model_name already exists. Skipping..."
    else
        echo "⬇️  Downloading $model_name..."
        ollama pull $model_name
    fi
}

build_persona(){
    model_file=$1
    model_alias=$2

    #initialize hash_cache to make sure persona isn't rebuilt unless file hash is changed
    persona_current_hash=$(md5sum "$model_file" | awk '{print $1}')

    if [ ! -f $hash_cache_file ]; then
        touch $hash_cache_file
        echo '{}' > $hash_cache_file
        echo "Hash file recreated..."
    fi

    persona_cached_hash=$(jq -r ".$model_alias" $hash_cache_file)

    if [[ ! -z "$persona_cached_hash" && $persona_cached_hash == $persona_current_hash ]]; then
        echo "$model_alias Persona has not changed. Skipping..."
    else
        echo "$model_alias Persona updated. Rebuilding..."
        ollama create $model_alias -f $model_file

        jq ".$model_alias=\"$persona_current_hash\"" $hash_cache_file > test_temp.json && mv test_temp.json $hash_cache_file
    fi
}

echo "Pulling Images..."

pull_model "llama3.1"
pull_model "gemma4"
pull_model "deepseek-r1"
pull_model "qwen3.5"
pull_model "qwen2.5-coder"

echo "Images All Pulled!!!"

echo "Building Personas ..."

for Modelfile in /app/my_models/*; do
    model_alias="${Modelfile#*.}"

    build_persona "$Modelfile" "$model_alias"
done

echo "Personas Booted!!!"


echo "AI standalone server is online."

wait $!