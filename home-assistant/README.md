# Home Assistant — конфиг для Wiren Board

## Файлы

| Файл | Куда копировать в HA |
|------|----------------------|
| `configuration.yaml` | `/config/configuration.yaml` |
| `scripts.yaml` | `/config/scripts.yaml` |

## Перед запуском

1. **Замени Modbus ID** в `configuration.yaml` (поиск `ЗАМЕНИ`):
   - `SLAVE` 90 → WB-MRM2-mini (сейчас placeholder)
   - `SLAVE` 91 → WB-M1W2
   - `SLAVE` 92 → WB-MAP3ET

2. **Проверь** `scripts.yaml` — скрипты WB-LED с `variables:` (без дубля `script:` в configuration.yaml).

3. **Check configuration** → Restart.

4. **MAP3ET энергия**: если кВт·ч не сходятся с Rilheva — попробуй убрать или сменить `swap: word` у uint64 сенсоров.

## Что исправлено относительно твоего конфига

- Убран **второй ключ `script:`** (конфликт с `!include scripts.yaml`).
- `message_wait_milliseconds: 150` (больше устройств на шине).
- Добавлены MRM2-mini, M1W2, MAP3ET.
