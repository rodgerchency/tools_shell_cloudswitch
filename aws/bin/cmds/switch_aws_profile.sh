#!/bin/bash
# MODE: EXPORT
# DESC: 切換 AWS Profile

profiles=$(aws configure list-profiles)
selected=$(echo "$profiles" | fzf --prompt="Select AWS Profile > ")

if [[ -n "$selected" ]]; then
  echo "export AWS_PROFILE=\"$selected\""
  echo "echo '✅ Switched to AWS profile: $selected'"
  echo "aws sts get-caller-identity"
else
  echo "echo '❌ No profile selected.'"
fi

