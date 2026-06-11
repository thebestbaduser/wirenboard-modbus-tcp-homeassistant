# Шаблоны Rilheva Modbus Poll

Шаблоны для первичной настройки устройств Wiren Board через USB-RS485 без контроллера.

Инструкция: https://wirenboard.com/wiki/Working_with_WB_devices_without_a_controller

## WB-M1W2

Карта регистров: https://wiki.wirenboard.com/wiki/M1W2_Registers

Каждый шаблон опрашивает **только вход 1** — минимальный набор + общие регистры.

| Файл | Назначение |
|------|------------|
| `templates/wb-m1w2-button.rilmp` | Вход 1, дискретный: состояние, счётчики нажатий |
| `templates/wb-m1w2-temp.rilmp` | Вход 1, 1-Wire: один датчик DS18B20 |

Перед использованием выставьте режим входа 1 в регистре **275** (`0` — 1-Wire, `1` — дискретный).

## WB-MRM2-mini v.2

Карта регистров: https://wiki.wirenboard.com/wiki/Relay_Module_Modbus_Management

| Файл | Назначение |
|------|------------|
| `templates/wb-mrm2-mini.rilmp` | 2 реле + 2 входа + общие регистры |

В [wb-community](https://github.com/wirenboard/wb-community/tree/main/templates/rilheva-modbus-poll/templates) отдельного шаблона для MRM2-mini нет. Ближайший — `wb-mr3xx-with-inputs.rilmp`, но он опрашивает **3-е реле** и **лишние входы** (3, 0), которых у MRM2-mini нет.
