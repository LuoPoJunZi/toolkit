<h1 align="center">⚙️ LuoPo VPS Toolkit</h1>
<div align="center">

一個面向 VPS 新手站長的終端工具箱。<br>
目標：**安裝即用、選單清晰、常見維運操作低門檻完成**。

[![Language](https://img.shields.io/badge/Language-Bash-4EAA25?style=flat-square&logo=gnu-bash)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-Ubuntu%20%7C%20Debian-0A66C2?style=flat-square)](#)
[![Version](https://img.shields.io/github/v/release/LuoPoJunZi/toolkit?display_name=tag&style=flat-square&label=Version)](https://github.com/LuoPoJunZi/toolkit/releases)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](LICENSE)

<br>

[![简体中文](https://img.shields.io/badge/简体中文-2f4858?style=for-the-badge)](README.md)
[![ENGLISH](https://img.shields.io/badge/ENGLISH-2f4858?style=for-the-badge)](README_en.md)
[![繁體中文](https://img.shields.io/badge/繁體中文-455a64?style=for-the-badge)](README_zh-TW.md)
[![日本語](https://img.shields.io/badge/日本語-455a64?style=for-the-badge)](README_ja.md)
[![한국어](https://img.shields.io/badge/한국어-455a64?style=for-the-badge)](README_ko.md)
[![РУССКИЙ](https://img.shields.io/badge/РУССКИЙ-455a64?style=for-the-badge)](README_ru.md)

</div>

---

## 繁體中文說明

`LuoPo VPS Toolkit` 是一個面向 Linux 新手站長的極簡 VPS 一鍵工具箱，支援 Ubuntu / Debian，整合系統維運、Docker 管理與精選腳本。

## 1. 這是什麼？適合誰用？

`LuoPo VPS Toolkit` 是純 Bash 的 VPS 選單工具，聚焦日常高頻操作：

- 系統資訊查詢
- 系統更新與清理
- 第三方優秀腳本一鍵整合
- Docker 管理
- 腳本更新與卸載

適合：

- 新手站長：希望「命令少、選單可視化」
- 維運使用者：希望快速執行標準操作
- 腳本維護者：希望在選單框架上擴充功能

---

## 2. 專案能力總覽

- 主選單緊湊雙欄布局
- 系統資訊面板分區展示（資源/網路/位置）
- 一鍵腳本中心分組展示（落魄的腳本 / 第三方腳本）
- 第三方腳本安全鏈路：下載 + SHA256 校驗
- Docker 常見維運選單化
- 更新機制：
  - Git 安裝：Git 更新 + 失敗回滾
  - 非 Git 安裝：自動切換遠端更新
- 一鍵卸載（`88`）完整清理安裝痕跡

---

## 3. 快速開始

### 3.1 一鍵安裝（推薦）

```bash
bash <(curl -fsSL https://z.evzzz.com)
```

### 3.2 備用安裝（GitHub Raw）

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/LuoPoJunZi/toolkit/main/install.sh)
```

### 3.3 啟動命令

```bash
z
```

英文介面：

```bash
z en
```

### 3.4 快速連結

- 網域安裝： `bash <(curl -fsSL https://z.evzzz.com)`
- GitHub 備用安裝： `bash <(curl -fsSL https://raw.githubusercontent.com/LuoPoJunZi/toolkit/main/install.sh)`
- 啟動工具箱： `z`
- 英文介面： `z en`

---

## 4. 主選單預覽

```text
========================================
LuoPo VPS Toolkit v0.1.2 (快捷启动: z)
========================================
 1. 系统信息查询       4. 一键脚本
 2. 系统全面更新       5. Docker 管理
 3. 系统垃圾清理
----------------------------------------
 99. 更新脚本          88. 卸载脚本
----------------------------------------
 0. 退出
========================================
请输入选择:
```

---

## 5. 一鍵腳本（選單 4）

```text
========================================
一键脚本
========================================
[落魄的脚本]
 1. 落魄 Hysteria2 一键脚本
 2. 落魄 Sing-box 一键脚本
[第三方脚本]
 3. 3X-UI 一键安装脚本
 4. F佬 Sing-box 一键脚本
 5. 老王 Sing-box 四合一
 6. 勇哥 Sing-box 四合一
 7. 233boy Sing-box 一键脚本
----------------------------------------
 0. 返回上级菜单
========================================
请输入脚本编号:
```

腳本索引檔案：

`integrations/index.json`

---

## 6. Docker 管理（選單 5）

```text
========================================
Docker 管理
========================================
 1. 安装 Docker         5. Docker 状态
 2. 启动 Docker         6. 查看容器列表
 3. 停止 Docker         7. 查看镜像列表
 4. 重启 Docker         8. 清理无用资源
----------------------------------------
 0. 返回上级
========================================
请输入选择:
```

---

## 7. 更新與回滾

選單 `99` 更新邏輯：

- Git 安裝：`fetch/merge`，失敗自動回滾到更新前 commit
- 非 Git 安裝：自動執行遠端更新（`https://z.evzzz.com`）

---

## 8. 卸載

選單 `88` 可一鍵卸載；也可手動執行：

```bash
rm -rf /opt/luopo-toolkit
rm -f /usr/local/bin/z
```

---

## 9. 目錄與日誌

- 安裝目錄：`/opt/luopo-toolkit`
- 啟動命令：`/usr/local/bin/z`
- 操作日誌：`logs/action.log`
- 錯誤日誌：`logs/error.log`

---

## 10. 開發與維護

### 10.1 本地執行

```bash
bash toolkit.sh
```

### 10.2 程式品質檢查

```bash
bash scripts/lint.sh
```

### 10.3 自動發佈

已內建 GitHub Actions 自動發佈流程：

- 僅核心代碼改動才觸發版本發佈
- 大改動（如主介面/核心重構）升級次版本（例如 `0.1.3 -> 0.2.0`）
- 小改動（功能增量）升級補丁版本（例如 `0.1.3 -> 0.1.4`）
- 自動更新 `VERSION` / `CHANGELOG`
- 自動打 Tag
- 自動建立 GitHub Release

工作流檔案：

`/.github/workflows/release.yml`

---

## 11. 開源協議

本專案基於 [MIT License](LICENSE) 開源。




