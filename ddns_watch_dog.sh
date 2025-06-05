#!/usr/bin/env bash
# ddns_watch_dog.sh: Monitor DNS changes and execute commands when IP changes.

CONFIG_FILE="dwd.conf"
TMP_FILE="${CONFIG_FILE}.tmp"

while IFS= read -r line; do
  # Skip empty lines and comments
  [[ -z "$line" || "$line" =~ ^# ]] && echo "$line" >> "$TMP_FILE" && continue

  domain=$(echo "${line}" | awk '{print $1}')
  old_ip=$(echo "${line}" | awk '{print $2}')
  work_dir=$(echo "${line}" | awk '{print $3}')
  cmd=$(echo "${line}" | cut -d' ' -f4-)
  # Remove leading and trailing quotes if present
  cmd=$(echo "$cmd" | sed -e 's/^"//' -e 's/"$//')

  current_ip=$(dig +short "$domain" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -n1)

  if [[ -n "$current_ip" && "$current_ip" != "$old_ip" ]]; then
    echo "IP for $domain changed: $old_ip -> $current_ip"
    (cd "$work_dir" && eval "$cmd")
    # Update the line with the new IP
    echo "$domain $current_ip $work_dir $cmd" >> "$TMP_FILE"
  else
    # No change, keep the original line
    echo "$line" >> "$TMP_FILE"
  fi
done < "$CONFIG_FILE"

# Replace the original config with the updated one
mv "$TMP_FILE" "$CONFIG_FILE"
