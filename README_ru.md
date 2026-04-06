<h1 align="center">⚙️ LuoPo VPS Toolkit</h1>
<div align="center">

Терминальный набор инструментов для начинающих пользователей VPS.<br>
Цель: **установил и сразу используешь, понятное меню, низкий порог для ежедневных задач администрирования**.

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

## Описание на русском

`LuoPo VPS Toolkit` — минималистичный one-click набор инструментов для начинающих пользователей Linux VPS. Поддерживает Ubuntu / Debian и объединяет системное администрирование, управление Docker и интеграцию проверенных скриптов.

## 1. Что это и для кого?

`LuoPo VPS Toolkit` — чистый Bash-меню инструмент для VPS, сфокусированный на частых ежедневных операциях:

- Просмотр системной информации
- Обновление и очистка системы
- One-click интеграция сторонних качественных скриптов
- Управление Docker
- Обновление и удаление самого тулкита

Подходит для:

- Начинающих вебмастеров: меньше команд, больше визуального меню
- Ops-пользователей: быстрое выполнение стандартных операций
- Поддерживающих скрипты: расширение функций поверх меню-фреймворка

---

## 2. Обзор возможностей

- Компактное двухколоночное главное меню
- Панель системной информации с разделами ресурсы/сеть/локация
- Центр one-click скриптов с группировкой (скрипты LuoPo / сторонние)
- Безопасная цепочка запуска сторонних скриптов: загрузка + SHA256-проверка
- Меню для типовых Docker-операций
- Механизм обновления:
  - Git-установка: обновление через Git + откат при ошибке
  - Не Git-установка: автоматический переход на удаленное обновление
- One-click удаление (`88`) с полной очисткой следов установки

---

## 3. Быстрый старт

### 3.1 Установка в один шаг (рекомендуется)

```bash
bash <(curl -fsSL https://z.evzzz.com)
```

### 3.2 Резервная установка (GitHub Raw)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/LuoPoJunZi/toolkit/main/install.sh)
```

### 3.3 Команда запуска

```bash
z
```

Английский интерфейс:

```bash
z en
```

### 3.4 Быстрые ссылки

- Установка через домен: `bash <(curl -fsSL https://z.evzzz.com)`
- Резервная установка через GitHub: `bash <(curl -fsSL https://raw.githubusercontent.com/LuoPoJunZi/toolkit/main/install.sh)`
- Запуск тулкита: `z`
- Запуск на английском UI: `z en`

---

## 4. Превью главного меню

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

## 5. One-click скрипты (меню 4)

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

Файл индекса скриптов:

`integrations/index.json`

---

## 6. Docker управление (меню 5)

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

## 7. Обновление и откат

Логика обновления в меню `99`:

- Git-установка: `fetch/merge`, при ошибке автооткат на commit до обновления
- Не Git-установка: автоматический запуск удаленного обновления (`https://z.evzzz.com`)

---

## 8. Удаление

Удаление через меню `88`, либо вручную:

```bash
rm -rf /opt/luopo-toolkit
rm -f /usr/local/bin/z
```

---

## 9. Каталоги и логи

- Каталог установки: `/opt/luopo-toolkit`
- Команда запуска: `/usr/local/bin/z`
- Лог операций: `logs/action.log`
- Лог ошибок: `logs/error.log`

---

## 10. Разработка и сопровождение

### 10.1 Локальный запуск

```bash
bash toolkit.sh
```

### 10.2 Проверка качества кода

```bash
bash scripts/lint.sh
```

### 10.3 Автоматический релиз

Встроен авто-релиз через GitHub Actions:

- Релиз версии только при изменениях в core-коде
- Крупные изменения (главный UI/рефактор core) повышают minor (например `0.1.3 -> 0.2.0`)
- Небольшие изменения (инкрементальные функции) повышают patch (например `0.1.3 -> 0.1.4`)
- Автообновление `VERSION` / `CHANGELOG`
- Автосоздание тега
- Автосоздание GitHub Release

Файл workflow:

`/.github/workflows/release.yml`

---

## 11. Лицензия

Проект распространяется по [MIT License](LICENSE).




