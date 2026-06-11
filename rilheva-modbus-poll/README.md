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

## WB-MAP3ET (счётчик, прошивка 2.x)

Карты регистров:

- Измерения: https://wiki.wirenboard.com/wiki/WB-MAP3E_Data_Registers_v.2
- Настройка (ТТ, RS-485): https://wiki.wirenboard.com/wiki/Power_Meter_WB-MAP3ET_Control_Registers

| Файл | Назначение |
|------|------------|
| `templates/wb-map3et-readings.rilmp` | U, I, P/Q/S, PF, частота, энергия, настройка ТТ, Modbus ID |

В wb-community шаблона для MAP3E/MAP3ET **нет**. Регистры и множители взяты из официального шаблона Wiren Board `config-map3e-fw2.json`.

**Энергия (кВт·ч):** в прошивке 2.x хранится в **u64 little-endian** (4 регистра подряд). В Rilheva для u64 используется `RegisterType: 5` (32 бита) — сверяйте показания с дисплеем/веб-интерфейсом; при расхождении на больших счётчиках нужна ручная сборка 4 регистров (см. wiki, раздел «Порядок байт»).

**MAP3ET:** коэффициент ТТ по умолчанию **2000** в регистрах 5216–5218.
