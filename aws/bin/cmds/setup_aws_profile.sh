#!/bin/bash
# MODE: NORMAL
# DESC: 初始化 AWS SSO Profile 與 SSO Session，並自動登入
set -euo pipefail

# 載入共用工具
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../" && pwd)
source "$SCRIPT_DIR/common/utils.sh"

CONFIG_FILE="$HOME/.aws/config"

# 檢查工具
command -v aws >/dev/null 2>&1 || { error "AWS CLI 未安裝"; exit 1; }

mkdir -p "$(dirname "$CONFIG_FILE")"

# 掃描現有 SSO Session
existing_sessions=$(grep '^\[sso-session ' "$CONFIG_FILE" | sed 's/\[sso-session \(.*\)\]/\1/' || true)

info "請選擇 SSO Session："
PS3="輸入數字選擇或輸入 0 新增新的 session > "
options=()
if [[ -n "$existing_sessions" ]]; then
    options+=($existing_sessions)
fi
options+=("新增新的 session")

select session_choice in "${options[@]}"; do
    if [[ -z "$session_choice" ]]; then
        warn "選擇無效，請重試"
        continue
    fi
    if [[ "$session_choice" == "新增新的 session" ]]; then
        read -p "請輸入新的 SSO Session 名稱: " SSO_SESSION
        [[ -z "$SSO_SESSION" ]] && { error "SSO Session 名稱不可空"; exit 1; }
        read -p "請輸入 SSO Start URL (預設 https://d-9667480a2d.awsapps.com/start): " SSO_START_URL
        SSO_START_URL=${SSO_START_URL:-https://d-9667480a2d.awsapps.com/start}
        read -p "請輸入 SSO Region (預設 ap-southeast-1): " SSO_REGION
        SSO_REGION=${SSO_REGION:-ap-southeast-1}
        NEW_SESSION=true
    else
        SSO_SESSION="$session_choice"
        # 取得已有 session 的 URL 與 region
        SSO_START_URL=$(awk -v s="$SSO_SESSION" '/\[sso-session/ {f=($2==s"]")} f && /^sso_start_url/ {print $3}' "$CONFIG_FILE")
        SSO_REGION=$(awk -v s="$SSO_SESSION" '/\[sso-session/ {f=($2==s"]")} f && /^sso_region/ {print $3}' "$CONFIG_FILE")
        NEW_SESSION=false
    fi
    break
done

# 新增 Profile 資訊
read -p "請輸入 Profile 名稱 (例如: igaming-data-report-prod): " PROFILE
[[ -z "$PROFILE" ]] && { warn "Profile 名稱為空，取消創建"; exit 0; }

read -p "請輸入 AWS Account ID: " ACCOUNT_ID

# Role 選擇
info "請選擇 Role:"
PS3="輸入數字選擇 Role 或選擇 4 自行輸入 > "
roles=("PowerUserAccess" "DataScientist" "ReadOnlyAccess" "自定義")
select role_choice in "${roles[@]}"; do
    if [[ -z "$role_choice" ]]; then
        warn "選擇無效，請重試"
        continue
    fi
    if [[ "$role_choice" == "自定義" ]]; then
        read -p "請輸入 Role 名稱: " ROLE_NAME
        [[ -z "$ROLE_NAME" ]] && { error "Role 名稱不可空"; exit 1; }
    else
        ROLE_NAME="$role_choice"
    fi
    break
done

read -p "請輸入 Profile Region (預設 ap-southeast-1): " PROFILE_REGION
PROFILE_REGION=${PROFILE_REGION:-ap-southeast-1}

# 移除舊 profile
awk -v p="$PROFILE" 'BEGIN{skip=0} /^\[profile /{skip=($2==p"]")} !skip' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" || true
mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"

# 如果是新增 session，先寫入 session
if [[ "$NEW_SESSION" == true ]]; then
    awk -v s="$SSO_SESSION" 'BEGIN{skip=0} /^\[sso-session /{skip=($2==s"]")} !skip' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" || true
    mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"

    cat >> "$CONFIG_FILE" <<EOF

[sso-session $SSO_SESSION]
sso_start_url = $SSO_START_URL
sso_region = $SSO_REGION
EOF
    success "新增 SSO Session [$SSO_SESSION]"
fi

# 寫入 profile
cat >> "$CONFIG_FILE" <<EOF

[profile $PROFILE]
sso_session = $SSO_SESSION
sso_account_id = $ACCOUNT_ID
sso_role_name = $ROLE_NAME
region = $PROFILE_REGION
EOF

success "Profile [$PROFILE] 已寫入 $CONFIG_FILE"

# 自動登入
info "🚀 開始 AWS SSO 登入 ($PROFILE)..."
aws sso login --profile "$PROFILE"
info "🟢 登入完成，驗證身份中..."
aws sts get-caller-identity --profile "$PROFILE"
success "✅ 驗證成功！"
