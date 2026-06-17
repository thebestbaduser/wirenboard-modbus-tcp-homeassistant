# Home Assistant — конфиг для Wiren Board

## Файлы

| Файл | Куда копировать в HA |
|------|----------------------|
| `configuration.yaml` | `/config/configuration.yaml` |
| `scripts.yaml` | `/config/scripts.yaml` |

## Два Modbus TCP-шлюза

| Хаб HA | Шлюз | IP:порт | UART | Устройства |
|--------|------|---------|------|------------|
| `wb_gateway` | HF2211S / EW11 | `172.16.22.192:502` | 9600 8N2 | MR6C **137, 242, 139, 145**; WB-LED **65** |
| `wb_gateway_line2` | **USR-DR164** | `172.16.22.11:502` | **115200** 8N2 | MRM2 **28**; M1W2 **20**; MAP3ET **13** |

Разные `host` — HA допускает несколько modbus-хабов. Дублировать один и тот же `host:port` нельзя.

У сущностей линии 2 задан `unique_id` (управление из UI HA). Подробнее — [главный README](../README.md).

## WB-LED (диммер)

- **`light.wbled_65_ch*`** — UI-диммер; состояние из `input_number.wbled_65_ch*_brightness`
- **`script.wbled_65_ch*_set`** — единственная запись в Modbus (автоматизации → сюда)
- **`sensor.wbled_65_ch*_raw`** — только диагностика, **не** управляет light

Пример lux-ночника: `automations.wbled-lux.example.yaml` (вызов скрипта, не `light.turn_on` по raw).

## Перед запуском

1. Скопируй файлы в `/config/`.
2. Убедись, что скрипты WB-LED только в `scripts.yaml` (без второго `script:` в configuration.yaml).
3. **Check configuration** → Restart.
4. MAP3ET: сверь `sensor.map3et_total_ap_energy` с Rilheva; при расхождении энергии — поправь `swap: word` у uint64.
