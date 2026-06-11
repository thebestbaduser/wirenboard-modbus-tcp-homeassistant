# Home Assistant — конфиг для Wiren Board

## Файлы

| Файл | Куда копировать в HA |
|------|----------------------|
| `configuration.yaml` | `/config/configuration.yaml` |
| `scripts.yaml` | `/config/scripts.yaml` |

## Параметры шины

| Параметр | Значение |
|----------|----------|
| Шлюз | `172.16.22.11:502` |
| WB-MR6C v.2 | ID 137, 242, 139, 145 |
| WB-LED | ID 65 |
| WB-MRM2-mini | ID **28** |
| WB-M1W2 | ID **20** |
| WB-MAP3ET | ID **13** |

## Перед запуском

1. Скопируй файлы в `/config/`.
2. Убедись, что скрипты WB-LED только в `scripts.yaml` (без второго `script:` в configuration.yaml).
3. **Check configuration** → Restart.
4. MAP3ET: сверь `sensor.map3et_total_ap_energy` с Rilheva; при расхождении энергии — поправь `swap: word` у uint64.
