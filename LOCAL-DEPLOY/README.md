# LOCAL-DEPLOY — срочный фикс WB-LED (ночник ch1)

**Не коммитить в git.** Только для копирования в твой `/config` на Home Assistant.

## Почему свет «сам» загорается

Старая схема: `light.wbled_65_ch1` брал `state`/`level` из `sensor.wbled_65_ch1_raw`.
Если на диммере в регистре > 0 (даже 56) — в HA лампа «включена», хотя автоматизация выключена.
Плюс lux-автоматизация реально крутит яркость ночью.

**Новая схема:** источник истины — `input_number.wbled_65_ch1_brightness`.
Запись в Modbus только через `script.wbled_65_ch1_set`. Raw — только диагностика.

---

## Скачать одним архивом

**`LOCAL-DEPLOY/wbled-ha-fix.zip`** — всё внутри, распакуй на ПК и копируй в HA.

## Файлы

| Файл | Куда |
|------|------|
| `0-SROCHNO-SEYCHAS.txt` | Прочитай первым |
| `CHECKLIST.txt` | Чеклист на одну страницу |
| `copy-to-config/scripts-wbled.yaml` | `/config/scripts.yaml` |
| `copy-to-config/input_number-wbled.yaml` | `/config/configuration.yaml` |
| `copy-to-config/modbus-wbled-raw.yaml` | modbus raw в `configuration.yaml` |
| `copy-to-config/template-lights-wbled.yaml` | 4× light в `configuration.yaml` |
| `copy-to-config/automations-lux-ch1-OFF.yaml` | lux **выкл** после рестарта (безопасно) |
| `copy-to-config/automations-lux-ch1.yaml` | lux вкл (когда фикс проверен) |

---

## Порядок действий

### 1. Срочно (см. `0-SROCHNO-SEYCHAS.txt`)

Отключи lux-автоматизацию или вызови `script.wbled_65_ch1_set` с `value: 0`.

### 2. scripts.yaml

Скопируй 4 скрипта `wbled_65_ch1_set` … `ch4_set` из `scripts.yaml` в свой `/config/scripts.yaml`.
Если скрипты уже есть — **замени целиком** (должны быть `input_number.set_value` + `modbus.write_register`).

### 3. configuration.yaml

**а)** После строки `script: !include scripts.yaml` добавь блок `input_number:` из `configuration-wbled-insert.yaml` (строки 4–28).

**б)** В `modbus:` → `wb_gateway` → `sensors` для `WBLED_65_ch*_raw` поставь `scan_interval: 30` (см. `modbus-wbled-raw-snippet.yaml`).

**в)** В `template:` → `light:` **замени** 4 блока `wbled_65_ch1`…`ch4`:
- `state` и `level` — из `input_number`, **не** из `sensor.*_raw`
- `turn_on` / `turn_off` / `set_level` — вызывают `script.wbled_65_ch*_set`

Готовые блоки — в `configuration-wbled-insert.yaml` (с строки 35).

**Старый шаблон (УДАЛИТЬ):**
```yaml
state: "{{ states('sensor.wbled_65_ch1_raw') | int(0) > 0 }}"
level: "{{ states('sensor.wbled_65_ch1_raw') | int(0) }}"
```

**Новый:**
```yaml
state: "{{ states('input_number.wbled_65_ch1_brightness') | int(0) > 0 }}"
level: "{{ states('input_number.wbled_65_ch1_brightness') | int(0) }}"
```

### 4. automations.yaml

Замени автоматизацию «WBLED ch1 диммер lux» на содержимое `automations-lux-ch1.yaml`.

Отличия от старой:
- управление через `script.wbled_65_ch1_set`, не `light.turn_on`
- пороги: `< 50` → 1%, `> 3000` → 0%
- не дёргает диммер, если разница < 1%

Пока не уверен в фиксе — **оставь автоматизацию выключенной** (шаг 1).

### 5. Проверка и перезагрузка

1. Настройки → Система → Проверить конфигурацию
2. Перезагрузить YAML configuration (или полный рестарт HA)
3. Developer Tools → Services: `script.wbled_65_ch1_set` → `value: 0`
4. Убедись: `light.wbled_65_ch1` = off, `input_number.wbled_65_ch1_brightness` = 0
5. `sensor.wbled_65_ch1_raw` может быть > 0 — **это нормально**, на light не влияет

### 6. Включить lux снова

Когда всё ок — включи автоматизацию в UI.

---

## Быстрая диагностика

| Симптом | Причина |
|---------|---------|
| Light «on» при выключенной автоматизации | Старый template читает `*_raw` |
| Свет реально горит ночью | Lux-автоматизация активна |
| После фикса light off, raw > 0 | Ожидаемо; синхронизируй скриптом value: 0 |

---

## Путь к папке в репозитории агента

`LOCAL-DEPLOY/` в корне `wirenboard-modbus-tcp-homeassistant`.

На Windows HA: Samba `\\IP_HA\config` или File editor / VS Code add-on.
