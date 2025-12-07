#!/bin/bash
# MODE: NORMAL
# DESC: 互動式新增 EKS kubeconfig

set -euo pipefail

# 載入共用工具
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../" && pwd)
source "$SCRIPT_DIR/common/utils.sh"


echo "🔧 選擇新增 kubeconfig 的方式："
options=("固定列表選擇" "透過 AWS 列出 cluster (需要 profile)")

mode=$(printf "%s\n" "${options[@]}" | fzf --height=6 --border --prompt="Select mode > " --ansi)
[[ -z "$mode" ]] && { yellow "[WARN] 已取消。"; exit 0; }

echo "[INFO] 你選擇了: $mode"

clusters_to_add=()
if [[ "$mode" == "固定列表選擇" ]]; then
    # 固定列表 cluster: region cluster profile
    eks_list=(
        "regionA clusterA profileA"
        "regionB clusterB profileB"
        "regionC clusterC profileC"
    )
    # fzf 多選，保留每行為一個元素
    clusters_to_add=()
    while IFS= read -r line; do
        clusters_to_add+=("$line")
    done < <(printf "%s\n" "${eks_list[@]}" | fzf --multi --height=10 --border --prompt="Select clusters > " --ansi)

    [[ ${#clusters_to_add[@]} -eq 0 ]] && { yellow "[WARN] 未選擇 cluster。"; exit 0; }

else
    # AWS 查詢模式
    profiles=$(aws configure list-profiles)
    AWS_PROFILE=$(echo "$profiles" | fzf --prompt="Select AWS Profile > ")

    [[ -z "$AWS_PROFILE" ]] && { red "[ERROR] Profile 不可空"; exit 1; }

    clusters=$(aws eks list-clusters --profile "$AWS_PROFILE" --query 'clusters' --output text)
    [[ -z "$clusters" ]] && { red "[ERROR] 該 profile 無 cluster"; exit 1; }

    # fzf 多選，兼容 macOS bash
    selected_clusters=()
    while IFS= read -r line; do
        selected_clusters+=("$line")
    done < <(printf "%s\n" $clusters | fzf --multi --height=10 --border --prompt="Select clusters > " --ansi)

    [[ ${#selected_clusters[@]} -eq 0 ]] && { yellow "[WARN] 未選擇 cluster。"; exit 0; }

    # 取得 region
    for c in "${selected_clusters[@]}"; do
        region=$(aws configure get region --profile "$AWS_PROFILE")
        clusters_to_add+=("$region $c $AWS_PROFILE")
    done

fi

# 執行 update-kubeconfig
echo "-----------------------------------------"
green "開始更新 kubeconfig..."
for entry in "${clusters_to_add[@]}"; do
    region=$(echo "$entry" | awk '{print $1}')
    cluster=$(echo "$entry" | awk '{print $2}')
    profile=$(echo "$entry" | awk '{print $3}')

    echo "✅ Updating cluster: $cluster (region: $region, profile: $profile)"
    aws eks update-kubeconfig --region "$region" --name "$cluster" --profile "$profile"
done

green "🎉 kubeconfig 更新完成！"
