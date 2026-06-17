# LOCAL-DEPLOY — срочный фикс WB-LED (ночник ch1)

**Не коммитить личные секреты.** Только для копирования в `/config` на Home Assistant.

---

## НУЖНЫ ПОЛНЫЕ ФАЙЛЫ? БЕРИ ЭТО

### Архив с тремя готовыми файлами

**[Скачать ha-full-config.zip](https://github.com/thebestbaduser/wirenboard-modbus-tcp-homeassistant/raw/cursor/wbled-local-deploy-5b1f/LOCAL-DEPLOY/ha-full-config.zip)**

Внутри `full-config/`:

| Файл | Действие |
|------|----------|
| `configuration.yaml` | **Заменить** `/config/configuration.yaml` целиком |
| `scripts.yaml` | **Заменить** `/config/scripts.yaml` целиком |
| `automations.yaml` | **Заменить** `/config/automations.yaml` (только lux; остальные — из бэкапа) |
| `КАК-СТАВИТЬ.txt` | Инструкция |

Прямые ссылки на файлы (без zip):

- [configuration.yaml](https://github.com/thebestbaduser/wirenboard-modbus-tcp-homeassistant/raw/cursor/wbled-local-deploy-5b1f/LOCAL-DEPLOY/full-config/configuration.yaml)
- [scripts.yaml](https://github.com/thebestbaduser/wirenboard-modbus-tcp-homeassistant/raw/cursor/wbled-local-deploy-5b1f/LOCAL-DEPLOY/full-config/scripts.yaml)
- [automations.yaml](https://github.com/thebestbaduser/wirenboard-modbus-tcp-homeassistant/raw/cursor/wbled-local-deploy-5b1f/LOCAL-DEPLOY/full-config/automations.yaml)

---

## Срочно погасить свет (до установки)

См. `0-SROCHNO-SEYCHAS.txt`

---

## Старый пакет с кусками (патчи)

Папка `copy-to-config/` — если нужны только фрагменты.  
Архив: `wbled-ha-fix.zip`

---

## Почему свет «сам» загорается

Старая схема: `light` брал state из `sensor.wbled_65_ch1_raw` → при raw > 0 лампа «on» в HA.  
Новая: `input_number` + `script.wbled_65_ch*_set`. Raw — только диагностика.
