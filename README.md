# Wiren Board WB-MR6C v.2 → Home Assistant через Modbus TCP-шлюз

Инструкция по подключению реле **Wiren Board WB-MR6C v.2** и диммера **WB-LED** к **Home Assistant** через TCP-шлюз Modbus RTU↔TCP — **без контроллера Wiren Board**, без MQTT-брокера и без скриптов на Python.

Проверено на:
- Шлюз: **HiFlying HF2211S** (аналогично должна работать линейка **EW11**)
- Реле: **WB-MR6C v.2** (4 шт., разные Modbus ID)
- Диммер: **WB-LED** (4 канала W, режим `4*W`)
- Home Assistant Core **2026.5+** (новый синтаксис template — см. ниже)

---

## Содержание

1. [Что понадобится](#что-понадобится)
2. [Идея подключения](#идея-подключения)
3. [Шаг 1. Настройка устройств без контроллера](#шаг-1-настройка-устройств-без-контроллера)
4. [Шаг 2. Настройка TCP-шлюза](#шаг-2-настройка-tcp-шлюза)
5. [Шаг 3. Базовый Modbus-блок в configuration.yaml](#шаг-3-базовый-modbus-блок-в-configurationyaml)
6. [Шаг 4. Реле WB-MR6C v.2](#шаг-4-реле-wb-mr6c-v2)
7. [Шаг 5. Светильники из реле (template light)](#шаг-5-светильники-из-реле-template-light)
8. [Шаг 6. Диммер WB-LED](#шаг-6-диммер-wb-led)
9. [Полный пример configuration.yaml](#полный-пример-configurationyaml)
10. [Типичные грабли](#типичные-грабли)

---

## Что понадобится

- Реле / диммеры Wiren Board с интерфейсом **RS-485 (Modbus RTU)**
- Шлюз **Modbus RTU ↔ TCP** (HF2211S, EW11, USR-TCP232 и т.п.) с настройкой `RS-485 ↔ TCP Server` на стороне Ethernet
- Home Assistant с включённой интеграцией `modbus` (входит в `default_config`)
- Однократно — USB-RS485 переходник + ПК с **Rilheva Modbus Poll** (бесплатная) для первоначальной настройки Modbus-адресов устройств

Документация:
- WB без контроллера: <https://wiki.wirenboard.com/wiki/Working_with_WB_devices_without_a_controller>
- Rilheva Modbus Poll: <https://wiki.wirenboard.com/wiki/Rilheva_Modbus_Poll>
- Общие регистры WB: <https://wiki.wirenboard.com/wiki/Common_Modbus_Registers>
- Шаблоны .rilmp от сообщества: <https://github.com/wirenboard/wb-community/tree/main/templates/rilheva-modbus-poll/templates>

---

## Идея подключения

```
[ HA ] ─── TCP ──→ [ HF2211S / EW11 ] ─── RS-485 ──→ [ WB-MR6C #1 ID=137 ]
                       (Modbus TCP                ↳→ [ WB-MR6C #2 ID=242 ]
                        ⇄ RTU                    ↳→ [ WB-MR6C #3 ID=139 ]
                        gateway)                 ↳→ [ WB-LED   ID=65  ]
                                                  ↳→ ...
```

На одной RS-485 шине висят все устройства с **уникальными Modbus ID** (1–247). HA общается со шлюзом по TCP (порт 502), шлюз прозрачно проксирует пакеты в RTU.

---

## Шаг 1. Настройка устройств без контроллера

Каждое реле/диммер по умолчанию имеет Modbus ID = 1. Если их у тебя несколько — нужно сначала задать разные ID, иначе они столкнутся на шине.

1. Подключи USB-RS485 переходник к ПК. В клеммах: A, B, GND.
2. Подключай устройства **по одному** (питание + RS-485).
3. Открой Rilheva Modbus Poll → подгрузи шаблон с GitHub `wb-community` (например `wb-mr6c-v2.rilmp`) → задай порт/скорость (по умолчанию 9600 8N2) → подключись.
4. Найди регистр **Modbus-адрес устройства** (`0x80` = 128) → запиши новый ID (137, 242, и т.д.) → сохрани.
5. Отключи, повтори для следующего устройства с другим ID.

После этого можно собирать всё на одной шине.

---

## Шаг 2. Настройка TCP-шлюза

В веб-интерфейсе HF2211S / EW11:

| Параметр | Значение |
|---|---|
| Режим работы | `TCP Server` |
| TCP-порт | `502` (стандарт Modbus TCP) |
| Скорость UART | `9600` (или то что выставлено в устройствах WB) |
| Биты данных | `8` |
| Стоп-биты | `2` |
| Чётность | `None` |
| Поток | `None` |
| Modbus mode | если есть отдельная галка "Modbus TCP↔RTU gateway" — **включить** |

Если в шлюзе есть опция явного режима **Modbus TCP-to-RTU**, обязательно включай — он будет правильно конвертировать пакеты (transaction_id, unit_id и т.д.). Без неё работает как «голый» TCP↔Serial, что тоже сойдёт, но менее надёжно при коллизиях.

Зафиксируй IP шлюза в DHCP-сервере или назначь статикой.

---

## Шаг 3. Базовый Modbus-блок в configuration.yaml

```yaml
modbus:
  - name: wb_gateway
    type: tcp
    host: 172.16.22.192       # IP шлюза
    port: 502
    timeout: 5
    message_wait_milliseconds: 100
    delay: 5                  # задержка перед первым опросом после старта HA
    # switches, sensors, binary_sensors, ... — см. ниже
```

**Параметры, которые реально важны:**

- `timeout: 5` — стандарт 3, у дешёвых TCP-шлюзов лучше 5, иначе будут `No response received after 3 retries` и закрытие соединения.
- `message_wait_milliseconds: 100` — пауза между запросами. Спасает шину от захлёбывания, особенно когда устройств много.
- `delay: 5` — HA подождёт 5 сек после старта перед опросом. Помогает если шлюз и HA стартуют одновременно.

> ⚠️ В современных версиях HA (`2025.x` и выше) **нельзя** создавать несколько `modbus` хабов с одинаковыми `host:port`. Если делаешь так — будет предупреждение `Configuration host/port for Modbus is duplicated`. Все устройства за одним шлюзом описываются в **одном** хабе `wb_gateway`.

---

## Шаг 4. Реле WB-MR6C v.2

Каналы реле — это **coils** с адресами `0..5` (по числу каналов). Чтение FC=01, запись FC=05.

```yaml
modbus:
  - name: wb_gateway
    type: tcp
    host: 172.16.22.192
    port: 502
    timeout: 5
    message_wait_milliseconds: 100
    delay: 5
    switches:
      # ===== Реле, Modbus ID 137 =====
      - name: RelayDom_01_137_K1
        slave: 137
        address: 0
        write_type: coil
        verify:                       # подтверждение состояния обратным чтением
          address: 0
          input_type: coil
      - name: RelayDom_01_137_K2
        slave: 137
        address: 1
        write_type: coil
        verify:
          address: 1
          input_type: coil
      # ... K3..K6 по аналогии (address: 2..5)

      # ===== Реле, Modbus ID 242 =====
      - name: RelayDom_02_242_K1
        slave: 242
        address: 0
        write_type: coil
        verify:
          address: 0
          input_type: coil
      # ... и т.д.
```

После рестарта HA в `Settings → Devices & Services → Entities` появятся `switch.relaydom_01_137_k1` … `_k6`.

### Почему именно coil

Регистры **coil** реализованы во встроенной интеграции `modbus` нативно: один бит = одно реле, есть штатный `verify` с обратным чтением. Через holding-регистры было бы избыточно.

---

## Шаг 5. Светильники из реле (template light)

Чтобы реле в Home Assistant были именно **светильниками** (со значком лампочки, попадали в light-группы и сценарии освещения), оборачиваем каждый `switch` в `template light`.

**Современный синтаксис HA 2025.x+** (старый `platform: template` под `light:` deprecated):

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

      # ... остальные каналы по аналогии
```

> Обратите внимание: в новом синтаксисе используется `action:` вместо `service:`, и все `turn_on`/`turn_off` — это **списки** действий (с дефисом перед `action:`).

---

## Шаг 6. Диммер WB-LED

WB-LED управляется через **holding-регистры прямого управления каналом**:

| Адрес | Канал | Диапазон |
|---|---|---|
| 90 | 1 (B) | 0..2048 |
| 91 | 2 (R) | 0..2048 |
| 92 | 3 (G) | 0..2048 |
| 93 | 4 (W) | 0..2048 |

В режиме `4*W` (регистр `4000 = 512`) или `W+W+W+W` (`4000 = 0`) все 4 канала независимые одноцветные.

### 6.1. Modbus sensors для чтения текущей яркости + физические входы

```yaml
modbus:
  - name: wb_gateway
    # ... настройки хаба ...
    sensors:
      - name: WBLED_65_ch1_raw
        slave: 65
        address: 90
        input_type: holding
        scan_interval: 5
      - name: WBLED_65_ch2_raw
        slave: 65
        address: 91
        input_type: holding
        scan_interval: 5
      - name: WBLED_65_ch3_raw
        slave: 65
        address: 92
        input_type: holding
        scan_interval: 5
      - name: WBLED_65_ch4_raw
        slave: 65
        address: 93
        input_type: holding
        scan_interval: 5

    binary_sensors:
      - name: WBLED_65_input_1
        slave: 65
        address: 0
        input_type: discrete_input
      - name: WBLED_65_input_2
        slave: 65
        address: 1
        input_type: discrete_input
      - name: WBLED_65_input_3
        slave: 65
        address: 2
        input_type: discrete_input
      - name: WBLED_65_input_4
        slave: 65
        address: 3
        input_type: discrete_input
```

### 6.2. Скрипты записи яркости

Встроенный сервис `modbus.write_register` принимает только число, поэтому пересчёт `brightness 0..255 → 0..2048` делается в скрипте:

```yaml
script:
  wbled_65_ch1_set:
    alias: WB-LED 65 ch1 set
    fields:
      value:
        description: "0..255"
        example: 128
    sequence:
      - variables:
          v: "{{ value | int(0) }}"
      - action: modbus.write_register
        data:
          hub: wb_gateway
          slave: 65
          address: 90
          value: "{{ (v * 2048 / 255) | int }}"

  # wbled_65_ch2_set / ch3 / ch4 — по аналогии, меняется только address: 91/92/93
```

Готовый файл со всеми четырьмя скриптами — [`scripts.example.yaml`](scripts.example.yaml).

> 📁 **Где располагать.** Если в `configuration.yaml` есть строка `script: !include scripts.yaml` — клади скрипты в свой `scripts.yaml` **без** верхнего ключа `script:` (как в `scripts.example.yaml`). Если такой строки нет — клади прямо в `configuration.yaml` под ключом `script:` (как в `configuration.example.yaml`). Дублировать ключ `script:` нельзя — HA выдаст ошибку.

> ⚠️ **Важно про `value` в скриптах.** В новых версиях HA, если просто использовать `{{ value }}` в шаблоне внутри `sequence`, можно получить `UndefinedError: 'value' is undefined`. Поэтому первым шагом делаем `variables:` и используем уже свою переменную `v`.

### 6.3. Template light с яркостью

Главная тонкость: для поддержки слайдера яркости в шаблоне **обязательно** нужны три вещи:
- `level:` — шаблон чтения текущей яркости (0..255)
- `set_level:` — отдельный блок действий, который HA вызовет при изменении яркости

Без `set_level:` светильник будет `supported_color_modes: onoff` (просто выключатель), даже если `level:` определён.

```yaml
template:
  - light:
      - unique_id: wbled_65_ch1
        name: "WBLED_65_CH1"
        default_entity_id: light.wbled_65_ch1
        state: "{{ (states('sensor.wbled_65_ch1_raw') | int(0)) > 0 }}"
        level: "{{ ((states('sensor.wbled_65_ch1_raw') | int(0)) * 255 / 2048) | int }}"
        turn_on:
          - action: script.wbled_65_ch1_set
            data:
              value: 255
        turn_off:
          - action: script.wbled_65_ch1_set
            data:
              value: 0
        set_level:
          - action: script.wbled_65_ch1_set
            data:
              value: "{{ brightness }}"

      # ch2 / ch3 / ch4 — по аналогии
```

После рестарта HA в `Developer Tools → States` у `light.wbled_65_ch1` должно появиться:
```
supported_color_modes: brightness
color_mode: brightness
brightness: <число 0..255>
```

---

## Полный пример configuration.yaml

См. файл [`configuration.example.yaml`](configuration.example.yaml) в этом репозитории.

---

## Типичные грабли

### 1. Дублирующиеся хабы Modbus

**Симптом:** `Configuration host/port for Modbus is duplicated`.

**Причина:** два `modbus:` блока с одинаковыми `host:port`.

**Лечение:** все устройства на одном шлюзе объединяй в один хаб `wb_gateway`. Не пытайся разносить по разным `name:` с тем же IP — современный HA так больше не умеет.

### 2. Одно мёртвое устройство ломает всю шину

**Симптом:** добавили в конфиг реле, физически его нет/не отвечает → таймауты сыпятся → **живые** устройства тоже отваливаются. В логах: `transaction_id mismatch`, `request ask for id=X but got id=Y`, `CLOSING CONNECTION`.

**Причина:** дешёвые TCP-шлюзы плохо переносят таймауты — теряют синхронизацию по transaction_id, и ответы от живых устройств приходят «не в свою очередь». HA закрывает соединение, переподключается, лавина ошибок.

**Лечение:**
- В `modbus:` поставь `timeout: 5`, `message_wait_milliseconds: 100`. Не делай `timeout: 1` — это не «быстрее», это «агрессивнее ломает».
- Если устройство физически не подключено — **закомментируй** его блок в конфиге, пока не подключишь. Иначе HA будет долбить пустоту и портить опрос остальных.
- После переподключения шлюза дай 10–20 секунд на восстановление коннекта — HA это делает с экспоненциальным backoff.

### 3. `value` is undefined в скриптах

**Симптом:** при вызове скрипта — `Error rendering data template: UndefinedError: 'value' is undefined`.

**Лечение:** см. п. 6.2 — оборачивай переданный `value` через `variables: v: "{{ value | int(0) }}"` и дальше используй `v`.

### 4. Template light = onoff вместо диммера

**Симптом:** в `Developer Tools → States` у `light.*` стоит `supported_color_modes: onoff`, слайдера нет.

**Причина:** нет блока `set_level:` в template-light. HA включает поддержку brightness только если этот блок существует.

**Лечение:** добавь `set_level:` (см. п. 6.3).

### 5. Старый синтаксис `light: - platform: template` deprecated

**Симптом:** ругань в логах HA: `Legacy light template deprecation ... Please migrate ...`.

**Лечение:** переехать на новый формат — `template:` → `- light:` (см. примеры выше). Старый формат будет удалён в HA 2026.6.

### 6. `bus`/`device`/`busport` в `ups.conf` для NUT

К Modbus не относится напрямую, но если в этом же проекте подключаешь UPS через NUT: **не** прописывай в `ups.conf` номер USB-устройства (`bus=`, `device=`, `busport=`). После каждого передёргивания кабеля номер меняется, драйвер перестаёт подбирать устройство. Достаточно `vendorid` и `productid`.

---

## Лицензия

MIT — пользуйся, форкай, улучшай.

## Источники

- [Wiren Board Wiki](https://wiki.wirenboard.com/)
- [wb-community templates](https://github.com/wirenboard/wb-community)
- [Home Assistant Modbus integration](https://www.home-assistant.io/integrations/modbus/)
- [Home Assistant Template integration](https://www.home-assistant.io/integrations/template/)
