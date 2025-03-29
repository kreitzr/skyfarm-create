#!/bin/bash

# Location of custom nodes
NODE_DIR="/app/ComfyUI/custom_nodes"
OUTPUT_FILE="/app/.node-versions"
CACHE_DIR="/tmp/repo-cache"

echo "📦 Extracting node versions from: $NODE_DIR"
mkdir -p "$CACHE_DIR"
> "$OUTPUT_FILE"

cd "$NODE_DIR" || exit 1

for dir in */; do
  dir=${dir%/}

  if [ -d "$dir" ] && [ ! -d "$dir/.git" ]; then
    # Try to extract GitHub repo URL from README or metadata
    repo_url=$(grep -Eo 'https://github\.com/[A-Za-z0-9._/-]+' "$dir"/README* "$dir"/*.json 2>/dev/null | head -n 1)

    if [ -n "$repo_url" ]; then
      # Add .git if missing
      [[ "$repo_url" != *.git ]] && repo_url="${repo_url}.git"

      repo_name=$(basename "$repo_url" .git)
      repo_cache="$CACHE_DIR/$repo_name"

      # Clone shallow copy if not already cached
      if [ ! -d "$repo_cache/.git" ]; then
        echo "🔍 Cloning $repo_url..."
        git clone --depth 1 "$repo_url" "$repo_cache" &>/dev/null
      fi

      # Extract commit hash
      if [ -d "$repo_cache/.git" ]; then
        hash=$(git -C "$repo_cache" rev-parse HEAD)
        echo "$dir|$repo_url|$hash" >> "$OUTPUT_FILE"
        echo "✅ $dir -> $hash"
      else
        echo "⚠️ Failed to clone: $repo_url"
      fi
    else
      echo "⚠️ No GitHub URL found in $dir"
    fi
  fi
done

echo "📝 Node versions written to $OUTPUT_FILE"