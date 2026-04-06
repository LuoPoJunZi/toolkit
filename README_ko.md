<h1 align="center">⚙️ LuoPo VPS Toolkit</h1>
<div align="center">

VPS 초보 사용자를 위한 터미널 툴킷입니다.<br>
목표: **설치 즉시 사용, 명확한 메뉴, 자주 하는 운영 작업을 쉽게 수행**.

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

## 한국어 설명

`LuoPo VPS Toolkit`은 Linux 초보 사용자를 위한 미니멀 VPS 원클릭 툴킷입니다. Ubuntu / Debian을 지원하며 시스템 운영, Docker 관리, 엄선된 스크립트 통합 기능을 제공합니다.

## 1. 무엇이고, 누구에게 적합한가?

`LuoPo VPS Toolkit`은 Bash 기반 VPS 메뉴 도구로, 일상적인 고빈도 작업에 집중합니다.

- 시스템 정보 조회
- 시스템 업데이트 및 정리
- 우수한 서드파티 스크립트 원클릭 통합
- Docker 관리
- 스크립트 업데이트 및 제거

적합한 대상:

- 초보 웹마스터: 명령어를 줄이고 메뉴 중심으로 사용하고 싶은 사용자
- 운영 사용자: 표준 작업을 빠르게 실행하고 싶은 사용자
- 스크립트 유지보수자: 메뉴 프레임워크 기반 확장을 원하는 사용자

---

## 2. 기능 개요

- 컴팩트한 2열 메인 메뉴
- 자원/네트워크/위치 정보를 포함한 시스템 정보 패널
- 그룹형 원클릭 스크립트 허브 (낙박 스크립트 / 서드파티 스크립트)
- 서드파티 실행 안전 체인: 다운로드 + SHA256 검증
- Docker 공통 운영의 메뉴화
- 업데이트 메커니즘:
  - Git 설치: Git 업데이트 + 실패 시 롤백
  - 비 Git 설치: 원격 업데이트로 자동 전환
- 원클릭 제거(`88`)로 설치 흔적 완전 정리

---

## 3. 빠른 시작

### 3.1 원클릭 설치 (권장)

```bash
bash <(curl -fsSL https://z.evzzz.com)
```

### 3.2 예비 설치 (GitHub Raw)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/LuoPoJunZi/toolkit/main/install.sh)
```

### 3.3 실행 명령

```bash
z
```

영문 UI:

```bash
z en
```

### 3.4 빠른 링크

- 도메인 설치： `bash <(curl -fsSL https://z.evzzz.com)`
- GitHub 예비 설치： `bash <(curl -fsSL https://raw.githubusercontent.com/LuoPoJunZi/toolkit/main/install.sh)`
- 도구 실행： `z`
- 영문 UI 실행： `z en`

---

## 4. 메인 메뉴 미리보기

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

## 5. 원클릭 스크립트 (메뉴 4)

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

스크립트 인덱스 파일:

`integrations/index.json`

---

## 6. Docker 관리 (메뉴 5)

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

## 7. 업데이트 및 롤백

메뉴 `99` 업데이트 로직:

- Git 설치: `fetch/merge`, 실패 시 업데이트 전 commit으로 자동 롤백
- 비 Git 설치: 원격 업데이트(`https://z.evzzz.com`) 자동 실행

---

## 8. 제거

메뉴 `88`에서 원클릭 제거 가능, 또는 수동 실행:

```bash
rm -rf /opt/luopo-toolkit
rm -f /usr/local/bin/z
```

---

## 9. 디렉터리 및 로그

- 설치 디렉터리: `/opt/luopo-toolkit`
- 실행 명령: `/usr/local/bin/z`
- 작업 로그: `logs/action.log`
- 오류 로그: `logs/error.log`

---

## 10. 개발 및 유지보수

### 10.1 로컬 실행

```bash
bash toolkit.sh
```

### 10.2 코드 품질 검사

```bash
bash scripts/lint.sh
```

### 10.3 자동 릴리스

GitHub Actions 자동 릴리스 워크플로 내장:

- 핵심 코드 변경 시에만 버전 릴리스 트리거
- 큰 변경(메인 UI/핵심 리팩터링)은 마이너 버전 상승 (예: `0.1.3 -> 0.2.0`)
- 작은 변경(기능 증분)은 패치 버전 상승 (예: `0.1.3 -> 0.1.4`)
- `VERSION` / `CHANGELOG` 자동 업데이트
- 태그 자동 생성
- GitHub Release 자동 생성

워크플로 파일:

`/.github/workflows/release.yml`

---

## 11. 라이선스

본 프로젝트는 [MIT License](LICENSE)로 배포됩니다.




