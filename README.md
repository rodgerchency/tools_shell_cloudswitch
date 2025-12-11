# Tools_Shell_CloudSwitch

提供 GCP / AWS 切換專案與 Kubernetes 叢集 的輔助工具。

## ⚙️ 安裝與設置


### GCP
```bash

# 注意：需於專案根目錄執行

# bash
echo 'export PATH="'$PWD'/gcp/bin:$PATH"' >> ~/.bash_profile
source ~/.bash_profile

# zsh
echo 'export PATH="'$PWD'/gcp/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# 啟動 GCP 工具
gutil

```

###  gutil 互動選單 
![gutil 互動選單](/assets/gutil_menu.png)

### AWS

```bash

# 注意：需於專案根目錄執行

# bash
echo 'export PATH="'$PWD'/aws/bin:$PATH"' >> ~/.bash_profile
source ~/.bash_profile

# zsh
echo 'export PATH="'$PWD'/aws/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# 啟動 AWS 工具
autil

```
### autil 互動選單 
![autil 互動選單](/assets/autil_menu.png)

## 專案結構
```bash
.
├── README.md
├── aws/
│   └── bin/
│       ├── autil                # AWS 共用工具
│       └── cmds/                # AWS 相關操作指令
│           ├── add_aws_context.sh
│           ├── delete_aws_profile.sh
│           ├── setup_aws_profile.sh
│           └── switch_aws_profile.sh
├── common/
│   ├── bin/
│   │   └── cmds/                # Kubernetes 通用 context 管理指令
│   │       ├── delete_k8s_context.sh
│   │       ├── rename_k8s_context.sh
│   │       └── switch_k8s_context.sh
│   └── utils.sh                 # 共用工具方法
└── gcp/
    └── bin/
        ├── cmds/                # GCP 專用操作指令
        │   ├── add_gcp_context.sh
        │   ├── switch_gcp_project.sh
        │   └── switch_gcp_sa.sh
        └── gutil                # GCP 共用工具
```