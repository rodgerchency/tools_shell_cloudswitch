#!/bin/bash
# MODE: NORMAL
# DESC: 互動式新增 GCP kubeconfig (GKE)

set -euo pipefail

# 載入共用工具
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../" && pwd)
source "$SCRIPT_DIR/common/utils.sh"

echo "🔧 選擇新增 kubeconfig 的方式："
options=("固定列表選擇" "透過 gc 列出 cluster")

mode=$(printf "%s\n" "${options[@]}" | fzf --height=6 --border --prompt="Select mode > " --ansi)
[[ -z "$mode" ]] && { yellow "[WARN] 已取消。"; exit 0; }

echo "[INFO] 你選擇了: $mode"

clusters_to_add=()

if [[ "$mode" == "固定列表選擇" ]]; then
    # 固定列表 cluster: 每行格式 "project region cluster"
    gke_list=(
        # gcp-project-dev gcp-xxxxxxxx-016
        "gcp-project-dev region cluster-name-dev"

        # bi-project-qa gcp-xxxxxxxx-017
        "gcp-project-id-qa region cluster-name-qa"

        # bi-project-staging gcp-xxxxxxxx-020
        "gcp-project-staging region cluster-name-staging"

        # bi-project-prod gcp-xxxxxxxx-018
        "gcp-project-prod region cluster-name-prod"
        
    )

    # fzf 多選
    while IFS= read -r line; do
        clusters_to_add+=("$line")
    done < <(printf "%s\n" "${gke_list[@]}" | fzf --multi --height=10 --border --prompt="Select clusters > " --ansi)

    [[ ${#clusters_to_add[@]} -eq 0 ]] && { yellow "[WARN] 未選擇 cluster。"; exit 0; }

else
    # 透過 gcloud 動態列出 clusters
    projects=$(gcloud projects list --filter="lifecycleState=ACTIVE" --format="value(name,projectId)")
    selected_project=$(echo "$projects" | fzf --prompt="Select GCP Project > ")
    [[ -z "$selected_project" ]] && { yellow "[WARN] 已取消。"; exit 0; }

    project_id=$(echo "$selected_project" | awk '{print $2}')
    echo "選到的 Project ID: $project_id"

    clusters=$(gcloud container clusters list \
    --project "$project_id" \
    --format="value(name,location)")
    selected_line=$(echo "$clusters" | fzf --prompt="Select GKE Cluster > ")
    [[ -z "$selected_line" ]] && { yellow "[WARN] 已取消。"; exit 0; }

    selected_cluster=$(echo "$selected_line" | awk '{print $1}')
    selected_region=$(echo "$selected_line" | awk '{print $2}')

    echo "selected_cluster: $selected_cluster , selected_region: $selected_region"
    clusters_to_add+=("$project_id $selected_region $selected_cluster")
fi

# 更新 kubeconfig
for entry in "${clusters_to_add[@]}"; do
    project=$(echo "$entry" | awk '{print $1}')
    region=$(echo "$entry" | awk '{print $2}')
    cluster=$(echo "$entry" | awk '{print $3}')

    green "✅ 更新 kubeconfig: project=$project, region=$region, cluster=$cluster"
    gcloud container clusters get-credentials "$cluster" --region "$region" --project "$project"
done

green "🎉 所有選擇的 kubeconfig 已更新！"
