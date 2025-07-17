#!/bin/bash

# Make sure both application folders exist
app_dirs=("/usr/share/applications" "$HOME/.local/share/applications")
for dir in "${app_dirs[@]}"; do
  [[ -d "$dir" ]] || continue
  find "$dir" -name "*.desktop"
done | xargs -I{} basename {} .desktop |
  sort |
  fzf --prompt="Select an app: " --height=20 --border |
  while read -r app; do
    if [[ -n "$app" ]]; then
      echo "Opening $app ..."
      # Try launching with gtk-launch (cleanly in background)
      (gtk-launch "$app" >/dev/null 2>&1 || nohup "$app" >/dev/null 2>&1 &) &
    else
      echo "No app selected."
    fi
  done
