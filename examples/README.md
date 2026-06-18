# examples/

Фрагменты для **GUI-редактора** Home Assistant (⋮ → Редактировать в YAML).

Не клади в `automations.yaml` на диске как есть — вставляй в редактор **одной** автоматизации (без `-` в начале).

| Файл | Назначение |
|------|------------|
| `automation-wbled-lux.gui.yaml` | Диммер ch1 по lux, 07:00–23:00 |
| `automation-wbled-night-off.gui.yaml` | Принудительно OFF, 23:00–07:00 |

Нужны `script.wbled_65_ch1_set` и `input_number.wbled_65_ch1_brightness` — см. `configuration.example.yaml` и `scripts.example.yaml`.
