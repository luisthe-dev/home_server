#!/bin/sh

ollama serve &

echo "Waiting for AI engine to initialize..."
until curl -s http://127.0.0.1:11434/api/tags > /dev/null; do
  sleep 5
done

echo "Verifying local models..."

pull_model() {
    model_name=$1
    if ollama list | grep -q "$model_name"; then
        echo "✅ Model $model_name already exists. Skipping..."
    else
        echo "⬇️  Downloading $model_name..."
        ollama pull $model_name
    fi
}

pull_model "llama3"
pull_model "gemma3"
pull_model "deepseek-r1"


echo "AI standalone server is online."

wait $!