<h1 align="center">⚙️ LuoPo VPS Toolkit</h1>
<div align="center">

VPS初心者向けのターミナルツールキット。<br>
目標：**インストールしてすぐ使える、明確なメニュー、日常運用を簡単に**。

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

## 日本語説明

`LuoPo VPS Toolkit` は Linux初心者向けのミニマルな VPS ワンクリックツールキットです。Ubuntu / Debian に対応し、システム運用、Docker 管理、厳選スクリプト連携を提供します。

> 简体中文: [README.md](README.md) | 英語: [README_en.md](README_en.md) | 繁體中文: [README_zh-TW.md](README_zh-TW.md) | 한국어: [README_ko.md](README_ko.md) | Русский: [README_ru.md](README_ru.md)

## 1. これは何ですか？誰向けですか？

`LuoPo VPS Toolkit` は Bash 製の VPS メニューツールで、日常の高頻度操作に特化しています。

- システム情報の確認
- システム更新とクリーンアップ
- 優秀なサードパーティスクリプトのワンクリック統合
- Docker 管理
- スクリプト更新とアンインストール

対象ユーザー：

- 初心者Web管理者：コマンドを減らしてメニュー中心で使いたい
- 運用ユーザー：標準操作を素早く実行したい
- スクリプト保守者：メニューフレームワーク上で機能拡張したい

---

## 2. 機能概要

- コンパクトな2カラムのメインメニュー
- リソース/ネットワーク/位置情報を含むシステム情報パネル
- グループ表示のワンクリックスクリプトセンター
- サードパーティ実行の安全チェーン：ダウンロード + SHA256 検証
- Docker の一般的な運用をメニュー化
- 更新メカニズム：
  - Git インストール：Git 更新 + 失敗時ロールバック
  - 非 Git インストール：リモート更新へ自動切替
- ワンクリック完全アンインストール（`88`）

---

## 3. クイックスタート

### 3.1 ワンクリックインストール（推奨）

```bash
bash <(curl -fsSL https://z.evzzz.com)
```

### 3.2 予備インストール（GitHub Raw）

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/LuoPoJunZi/toolkit/main/install.sh)
```

### 3.3 起動コマンド

```bash
z
```

英語UI：

```bash
z en
```

### 3.4 クイックリンク

- ドメイン経由インストール： `bash <(curl -fsSL https://z.evzzz.com)`
- GitHub予備インストール： `bash <(curl -fsSL https://raw.githubusercontent.com/LuoPoJunZi/toolkit/main/install.sh)`
- ツール起動： `z`
- 英語UI起動： `z en`

---

## 4. メインメニュープレビュー

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

## 5. ワンクリックスクリプト（メニュー 4）

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

スクリプト索引ファイル：

`integrations/index.json`

---

## 6. Docker 管理（メニュー 5）

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

## 7. 更新とロールバック

メニュー `99` の更新ロジック：

- Git インストール：`fetch/merge`、失敗時は更新前 commit へ自動ロールバック
- 非 Git インストール：リモート更新（`https://z.evzzz.com`）を自動実行

---

## 8. アンインストール

メニュー `88` でワンクリック卸載、または手動実行：

```bash
rm -rf /opt/luopo-toolkit
rm -f /usr/local/bin/z
```

---

## 9. ディレクトリとログ

- インストール先：`/opt/luopo-toolkit`
- 起動コマンド：`/usr/local/bin/z`
- 操作ログ：`logs/action.log`
- エラーログ：`logs/error.log`

---

## 10. 開発と保守

### 10.1 ローカル実行

```bash
bash toolkit.sh
```

### 10.2 コード品質チェック

```bash
bash scripts/lint.sh
```

### 10.3 自動リリース

GitHub Actions 自動リリースフローを内蔵：

- コアコード変更時のみバージョンリリース
- 大規模変更（メインUI/コア再構築）はマイナーバージョン更新（例：`0.1.3 -> 0.2.0`）
- 小規模変更（機能追加）はパッチ更新（例：`0.1.3 -> 0.1.4`）
- `VERSION` / `CHANGELOG` を自動更新
- タグ自動作成
- GitHub Release 自動作成

ワークフローファイル：

`/.github/workflows/release.yml`

---

## 11. ライセンス

本プロジェクトは [MIT License](LICENSE) で公開されています。




