# Home Assistant — конфиг для Wiren Board

## Файлы

| Файл | Куда копировать в HA |
|------|----------------------|
| `configuration.yaml` | `/config/configuration.yaml` |
| `scripts.yaml` | `/config/scripts.yaml` |

## Два Modbus TCP-шлюза

| Шлюз | IP:порт | Устройства |
|------|---------|------------|
| `wb_gateway` (старая линия) | `172.16.22.192:502` | WB-MR6C v.2: **137, 242, 139, 145**; WB-LED: **65** |
| `wb_gateway_line2` (новая линия) | `172.16.22.11:502` | WB-MRM2-mini: **28**; WB-M1W2: **20**; WB-MAP3ET: **13** |

Разные `host` — HA допускает несколько modbus-хабов. Дублировать один и тот же `host:port` нельзя.

## Перед запуском

1. Скопируй файлы в `/config/`.
2. Убедись, что скрипты WB-LED только в `scripts.yaml` (без второго `script:` в configuration.yaml).
3. **Check configuration** → Restart.
4. MAP3ET: сверь `sensor.map3et_total_ap_energy` с Rilheva; при расхождении энергии — поправь `swap: word` у uint64.
