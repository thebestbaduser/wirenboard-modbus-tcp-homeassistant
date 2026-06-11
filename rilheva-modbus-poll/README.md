# Шаблоны Rilheva Modbus Poll

Шаблоны для первичной настройки **WB-M1W2** через USB-RS485 без контроллера.

Инструкция: https://wirenboard.com/wiki/Working_with_WB_devices_without_a_controller  
Карта регистров: https://wiki.wirenboard.com/wiki/M1W2_Registers

Каждый шаблон опрашивает **только вход 1** — минимальный набор регистров + общие (как в [wb-community](https://github.com/wirenboard/wb-community/tree/main/templates/rilheva-modbus-poll/templates)).

| Файл | Назначение |
|------|------------|
| `templates/wb-m1w2-button.rilmp` | Вход 1 в режиме дискретного входа: состояние, счётчики нажатий |
| `templates/wb-m1w2-temp.rilmp` | Вход 1 в режиме 1-Wire: один датчик DS18B20 |

Перед использованием выставьте режим входа 1 в регистре **275** (`0` — 1-Wire, `1` — дискретный).
