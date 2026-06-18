# Wiren Board → Home Assistant через Modbus TCP-шлюз

Инструкция и готовые конфиги для подключения устройств **Wiren Board** к **Home Assistant** через TCP-шлюзы Modbus RTU↔TCP — **без контроллера Wiren Board**, без MQTT-брокера и без скриптов на Python.

## Проверено на

| Линия RS-485 | Шлюз | IP:порт | Скорость UART | Устройства |
|---|---|---|---|---|
| Старая | **HiFlying HF2211S** (аналог **EW11**) | `172.16.22.192:502` | **9600**, 8N2 | 4× WB-MR6C v.2 (ID 137, 242, 139, 145), WB-LED (ID 65) |
| Новая | **PUSR USR-DR164** | `172.16.22.11:502` | **115200**, 8N2 | WB-MRM2-mini (ID 28), WB-M1W2 (ID 20), WB-MAP3ET (ID 13) |

Home Assistant Core **2026.5+** (новый синтаксис `template` — см. ниже).

---

## Содержание

1. [Структура репозитория](#структура-репозитория)
2. [Что понадобится](#что-понадобится)
3. [Идея подключения](#идея-подключения)
4. [Шаг 1. Настройка устройств без контроллера](#шаг-1-настройка-устройств-без-контроллера)
5. [Шаг 2. Настройка TCP-шлюзов](#шаг-2-настройка-tcp-шлюзов)
6. [Шаг 3. Modbus в Home Assistant](#шаг-3-modbus-в-home-assistant)
7. [Шаг 4. Реле WB-MR6C v.2](#шаг-4-реле-wb-mr6c-v2)
8. [Шаг 5. Светильники из реле (template light)](#шаг-5-светильники-из-реле-template-light)
9. [Шаг 6. Диммер WB-LED](#шаг-6-диммер-wb-led)
10. [Шаг 7. WB-MRM2-mini, WB-M1W2, WB-MAP3ET](#шаг-7-wb-mrm2-mini-wb-m1w2-wb-map3et)
11. [Примеры для Home Assistant](#примеры-для-home-assistant)
12. [Шаблоны Rilheva Modbus Poll](#шаблоны-rilheva-modbus-poll)
13. [Типичные грабли](#типичные-грабли)

---

## Структура репозитория

```
wirenboard-modbus-tcp-homeassistant/
├── README.md                          ← эта инструкция
├── configuration.example.yaml         ← пример modbus + WB-LED (одна линия)
├── scripts.example.yaml               ← скрипты яркости WB-LED (отдельный include)
├── examples/
│   ├── automation-wbled-lux.gui.yaml       ← lux-диммер (GUI-редактор)
│   └── automation-wbled-night-off.gui.yaml ← тишина 23:00–07:00 (GUI)
└── rilheva-modbus-poll/
    ├── README.md
    └── templates/
        ├── wb-m1w2-button.rilmp       ← M1W2, дискретный вход 1
        ├── wb-m1w2-temp.rilmp         ← M1W2, DS18B20 на входе 1
        ├── wb-mrm2-mini.rilmp         ← MRM2-mini (2 реле + входы)
        └── wb-map3et-readings.rilmp   ← MAP3ET (U, I, P, энергия, настройка ТТ)
```

Ветка с полным набором изменений: [`cursor/wb-m1w2-rilmp-template-5b1f`](https://github.com/thebestbaduser/wirenboard-modbus-tcp-homeassistant/tree/cursor/wb-m1w2-rilmp-template-5b1f).

---

## Что понадобится

- Устройства Wiren Board с интерфейсом **RS-485 (Modbus RTU)**
- Один или несколько шлюзов **Modbus RTU ↔ TCP**:
  - **HF2211S / EW11** — проверено на первой линии (9600)
  - **USR-DR164** (PUSR) — проверено на второй линии (115200)
  - Подойдут и другие (USR-TCP232 и т.п.) при правильной скорости и режиме gateway
- Home Assistant с интеграцией `modbus` (входит в `default_config`)
- Однократно — USB-RS485 + ПК с **Rilheva Modbus Poll** для первичной настройки Modbus ID

Документация:
- WB без контроллера: <https://wiki.wirenboard.com/wiki/Working_with_WB_devices_without_a_controller>
- Rilheva Modbus Poll: <https://wiki.wirenboard.com/wiki/Rilheva_Modbus_Poll>
- Общие регистры WB: <https://wiki.wirenboard.com/wiki/Common_Modbus_Registers>
- Шаблоны .rilmp от сообщества: <https://github.com/wirenboard/wb-community/tree/main/templates/rilheva-modbus-poll/templates>
- USR-DR164 (мануал): <https://www.pusr.com/support/download/User-Manual-USR-DR164-User-Manual-EN-V1.html>

---

## Идея подключения

Две независимые RS-485 линии — два TCP-шлюза — два modbus-хаба в HA:

```
[ HA ] ──TCP──→ [ HF2211S / EW11 ] ──RS-485──→ MR6C×4, WB-LED
      │              172.16.22.192:502
      │              9600 8N2
      │
      └──TCP──→ [ USR-DR164 ] ──RS-485──→ MRM2-mini, M1W2, MAP3ET
                    172.16.22.11:502
                    115200 8N2
```

На каждой шине устройства с **уникальными Modbus ID** (1–247). HA общается со шлюзом по TCP (порт 502), шлюз проксирует пакеты в RTU.

> В HA (`2025.x`+) **нельзя** дублировать один и тот же `host:port` в двух modbus-хабах. **Разные IP** — можно: `wb_gateway` + `wb_gateway_line2`.

---

## Шаг 1. Настройка устройств без контроллера

Каждое устройство по умолчанию имеет Modbus ID = 1. Если их несколько — задай разные ID до сборки на одной шине.

1. Подключи USB-RS485 к ПК (A, B, GND).
2. Подключай устройства **по одному** (питание + RS-485).
3. Rilheva Modbus Poll → шаблон из [`rilheva-modbus-poll/templates/`](rilheva-modbus-poll/templates/) или `wb-community` → порт и **скорость как на будущей линии** (9600 или 115200).
4. Регистр **Modbus-адрес** (`0x80` = 128) → запиши новый ID → сохрани.
5. Повтори для следующего устройства.

Шаблоны для устройств, которых нет в wb-community (M1W2, MRM2-mini, MAP3ET) — в этом репозитории, см. [ниже](#шаблоны-rilheva-modbus-poll).

---

## Шаг 2. Настройка TCP-шлюзов

### HF2211S / EW11 (линия 1, проверено)

| Параметр | Значение |
|---|---|
| Режим | `TCP Server` |
| TCP-порт | `502` |
| Скорость UART | `9600` |
| Биты / стоп / чётность | `8` / `2` / `None` |
| Modbus gateway | **включить** (TCP↔RTU), если есть опция |

### USR-DR164 (линия 2, проверено)

Веб-интерфейс: по Wi‑Fi AP устройства (`USR-DR164-xxxx`) → `10.10.100.254` (логин `admin` / `admin`), либо по IP в LAN после настройки STA.

**Serial Setting → UART SET**

| Параметр | Значение |
|---|---|
| Baud Rate | **115200** |
| Data Bit | 8 |
| Parity Bit | None |
| Stop Bit | **2** |
| CTSRTS | Disable |
| Pack Interval | 20 |
| Pack Size | 1400 |
| Com Heart | OFF |
| ModBUS Enabled | **Protocol Conversion** |

**Net Setting → Socket A Set** (Socket B — `NONE`, выключен)

| Параметр | Значение |
|---|---|
| Protocol | **TCP-Server** |
| Port ID | **502** |
| TCP Time Out Setting | 300 |
| Net heart | OFF |
| Reg Set | OFF |

На обеих линиях зафиксируй IP шлюза (статика или резервация DHCP).

---

## Шаг 3. Modbus в Home Assistant

### Один шлюз (пример)

```yaml
modbus:
  - name: wb_gateway
    type: tcp
    host: 172.16.22.192
    port: 502
    timeout: 5
    message_wait_milliseconds: 100
    delay: 5
```

### Два шлюза (пример структуры)

```yaml
modbus:
  - name: wb_gateway          # линия 1 — MR6C, WB-LED
    type: tcp
    host: 172.16.22.192
    port: 502
    timeout: 5
    message_wait_milliseconds: 100
    delay: 5
    switches: [ ... ]
    sensors: [ ... ]
    binary_sensors: [ ... ]

  - name: wb_gateway_line2     # линия 2 — MRM2, M1W2, MAP3ET
    type: tcp
    host: 172.16.22.11
    port: 502
    timeout: 5
    message_wait_milliseconds: 150   # чуть больше пауза — на линии счётчик + несколько устройств
    delay: 5
    switches: [ ... ]
    sensors: [ ... ]
    binary_sensors: [ ... ]
```

**Параметры, которые реально важны:**

- `timeout: 5` — у дешёвых шлюзов лучше 5, иначе `No response received after 3 retries`.
- `message_wait_milliseconds: 100–150` — пауза между запросами, снижает коллизии на шине.
- `delay: 5` — HA ждёт после старта перед первым опросом.

**`unique_id`:** для modbus-сущностей без него HA пишет *«нет уникального идентификатора»* и не даёт менять имя/иконку в UI. В готовом конфиге для линии 2 все сущности уже с `unique_id` (например `unique_id: mrm2_mini_k1` у переключателя MRM2).

---

## Шаг 4. Реле WB-MR6C v.2

Каналы — **coils** `0..5`. Чтение FC=01, запись FC=05.

```yaml
switches:
  - name: RelayDom_01_137_K1
    slave: 137
    address: 0
    write_type: coil
    verify:
      address: 0
      input_type: coil
  # K2..K6: address 1..5; другие реле — другой slave
```

После рестарта: `switch.relaydom_01_137_k1` … `_k6`.

---

## Шаг 5. Светильники из реле (template light)

Синтаксис HA 2025.x+:

```yaml
template:
  - light:
      - unique_id: relaydom_01_137_k1
        name: "RelayDom_01_137_K1"
        default_entity_id: light.relaydom_01_137_k1
        state: "{{ is_state('switch.relaydom_01_137_k1', 'on') }}"
        turn_on:
          - action: switch.turn_on
            target:
              entity_id: switch.relaydom_01_137_k1
        turn_off:
          - action: switch.turn_off
            target:
              entity_id: switch.relaydom_01_137_k1
```

Используй `action:` (не `service:`), `turn_on`/`turn_off` — списки действий.

---

## Шаг 6. Диммер WB-LED

| Адрес holding | Канал | Диапазон |
|---|---|---|
| 90 | 1 | 0..2048 |
| 91 | 2 | 0..2048 |
| 92 | 3 | 0..2048 |
| 93 | 4 | 0..2048 |

Режим `4*W`: регистр `4000 = 512`.

### Схема управления (без обратной связи raw → light)

```
Автоматизация / UI → script.wbled_65_ch1_set
        ↓
input_number.wbled_65_ch1_brightness  ← источник истины для light.*
        ↓
modbus.write_register (регистр 90..93)

sensor.wbled_65_ch1_raw — только диагностика (сверка с железом), на light не влияет
```

Свет **не «включается сам»** при опросе Modbus — только когда кто-то вызвал скрипт или `light.*`.

### input_number + modbus sensors

```yaml
input_number:
  wbled_65_ch1_brightness:
    name: WBLED 65 CH1 brightness
    min: 0
    max: 255
    step: 1
    mode: slider

modbus:
  sensors:
    - name: WBLED_65_ch1_raw   # диагностика, scan_interval: 30
      slave: 65
      address: 90
      input_type: holding
```

### Скрипт (единственная точка записи)

[`scripts.example.yaml`](scripts.example.yaml) — обновляет `input_number` и пишет в Modbus. Автоматизации (lux и др.) вызывают **`script.wbled_65_ch1_set`** с `value: 0..255`.

### Template light

`state` и `level` — из **`input_number`**, не из raw. Нужны `set_level:` для диммера.

```yaml
- unique_id: wbled_65_ch1
  name: "WBLED_65_CH1"
  state: "{{ states('input_number.wbled_65_ch1_brightness') | int(0) > 0 }}"
  level: "{{ states('input_number.wbled_65_ch1_brightness') | int(0) }}"
  set_level:
    - action: script.wbled_65_ch1_set
      data:
        value: "{{ brightness }}"
```

Примеры автоматизаций WB-LED (вставка в GUI, не в `automations.yaml` на диске):

- [`examples/automation-wbled-lux.gui.yaml`](examples/automation-wbled-lux.gui.yaml) — lux 07:00–23:00
- [`examples/automation-wbled-night-off.gui.yaml`](examples/automation-wbled-night-off.gui.yaml) — гасит с 23:00 до 07:00

---

## Шаг 7. WB-MRM2-mini, WB-M1W2, WB-MAP3ET

Устройства на **второй линии** (`wb_gateway_line2`, USR-DR164, 115200).

| Устройство | Modbus ID | Сущности в HA |
|---|---|---|
| WB-MRM2-mini v.2 | **28** | `switch.mrm2_mini_k1/k2`, binary_sensor входы и факт. состояние реле (96–97) |
| WB-M1W2 | **20** | `sensor.m1w2_input1_temperature`, счётчики нажатий, binary_sensor кнопка/DS18B20 |
| WB-MAP3ET | **13** | `sensor.map3et_*` — U, I, P/Q/S, PF, частота, энергия (kWh) |

### MRM2-mini

```yaml
switches:
  - name: MRM2_mini_K1
    unique_id: mrm2_mini_k1
    slave: 28
    address: 0
    write_type: coil
    verify:
      address: 96          # фактическое состояние (FW ≥ 1.24)
      input_type: discrete_input
```

### M1W2

- Температура входа 1: input reg **7**, `int16`, `scale: 0.0625`
- Режим входа 1: holding **275** (`0` = 1-Wire, `1` = дискретный)
- Кнопка: discrete **0**; статус DS18B20: discrete **16**

### MAP3ET

Ключевые регистры (прошивка 2.x):

| Величина | Адрес | Тип |
|---|---|---|
| Total P | 4864 | int32 |
| Urms L1 | 5136 | uint32 |
| Irms L1 | 5142 | uint32 |
| Total AP energy | 4608 | uint64, `swap: word` |
| Частота | 4344 | uint16, scale 0.01 |

Энергию сверяй с Rilheva/дисплеем; при расхождении — подбери `swap` для uint64.

---

## Примеры для Home Assistant

Репозиторий — **инструкция и примеры modbus**, не личный `/config`. Готовые фрагменты:

| Файл | Назначение |
|---|---|
| [`configuration.example.yaml`](configuration.example.yaml) | Modbus MR6C + WB-LED, template light, input_number (одна линия) |
| [`scripts.example.yaml`](scripts.example.yaml) | Скрипты `wbled_65_ch*_set` для `script: !include` |
| [`examples/automation-wbled-lux.gui.yaml`](examples/automation-wbled-lux.gui.yaml) | Lux-диммер ch1 (GUI) |
| [`examples/automation-wbled-night-off.gui.yaml`](examples/automation-wbled-night-off.gui.yaml) | Ночная тишина 23:00–07:00 (GUI) |

Скопируй нужные куски в свой `/config`, подставь свои IP и Modbus ID. Полный конфиг с двумя шлюзами и MAP3ET — собери по разделам 3 и 7 этой инструкции.

---

## Шаблоны Rilheva Modbus Poll

Каталог [`rilheva-modbus-poll/`](rilheva-modbus-poll/) — шаблоны `.rilmp` для настройки без контроллера WB.

| Файл | Устройство | Статус |
|---|---|---|
| `wb-m1w2-button.rilmp` | M1W2, дискретный вход 1 | проверено |
| `wb-m1w2-temp.rilmp` | M1W2, DS18B20 | проверено |
| `wb-mrm2-mini.rilmp` | MRM2-mini | проверено (реле) |
| `wb-map3et-readings.rilmp` | MAP3ET | проверено (подключение; энергию сверить на объекте) |

В [wb-community](https://github.com/wirenboard/wb-community/tree/main/templates/rilheva-modbus-poll/templates) шаблонов для M1W2, MRM2-mini и MAP3ET **нет** — добавлены в этом репозитории.

Подробности по регистрам: [`rilheva-modbus-poll/README.md`](rilheva-modbus-poll/README.md).

Отправка шаблонов в официальный [wb-community](https://github.com/wirenboard/wb-community): [`contrib/wb-community-pr/`](contrib/wb-community-pr/).

---

## Типичные грабли

### 1. Дублирующиеся хабы Modbus

**Симптом:** `Configuration host/port for Modbus is duplicated`.

**Причина:** два хаба с **одинаковыми** `host:port`.

**Лечение:** разные шлюзы — разные IP (`172.16.22.192` и `172.16.22.11`). На **одном** шлюзе все устройства — в **одном** хабе.

### 2. Несовпадение скорости шлюза и устройств

**Симптом:** таймауты, `No response`, случайные ответы.

**Лечение:** скорость и формат кадра (8N2) на шлюзе = на всех WB на этой линии. Линия 1: **9600**. Линия 2 (USR-DR164): **115200**.

### 3. Одно мёртвое устройство ломает шину

Закомментируй в конфиге устройства, которых физически нет. `timeout: 5`, `message_wait_milliseconds: 100–150`.

### 4. Нет `unique_id` у modbus-сущности

**Симптом:** *«У этого объекта нет уникального идентификатора»* — нельзя переименовать в UI.

**Лечение:** добавь `unique_id:` в блок modbus (см. пример MRM2 в [шаге 7](#шаг-7-wb-mrm2-mini-wb-m1w2-wb-map3et)).

### 5. `value` is undefined в скриптах WB-LED

Используй `variables: v: "{{ value | int(0) }}"` — см. [`scripts.example.yaml`](scripts.example.yaml).

### 6. Template light = onoff вместо диммера

Добавь блок `set_level:`.

### 7. Два ключа `script:` в configuration.yaml

Только `script: !include scripts.yaml`. Inline-скрипты `wbled_*` в том же файле — ошибка конфигурации.

### 8. Старый синтаксис template light deprecated

Переходи на `template:` → `- light:` с `action:` (HA 2026.6 уберёт legacy).

---

## Лицензия

MIT — пользуйся, форкай, улучшай.

## Источники

- [Wiren Board Wiki](https://wiki.wirenboard.com/)
- [wb-community templates](https://github.com/wirenboard/wb-community)
- [Home Assistant Modbus](https://www.home-assistant.io/integrations/modbus/)
- [Home Assistant Template](https://www.home-assistant.io/integrations/template/)
- [USR-DR164 User Manual](https://www.pusr.com/support/download/User-Manual-USR-DR164-User-Manual-EN-V1.html)
