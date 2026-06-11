## Rilheva Modbus Poll: WB-M1W2, WB-MRM2-mini, WB-MAP3ET

Добавлены шаблоны `.rilmp` для первичной настройки устройств Wiren Board через [Rilheva Modbus Poll](https://wirenboard.com/wiki/Rilheva_Modbus_Poll) **без контроллера WB**.

В [wb-community](https://github.com/wirenboard/wb-community/tree/main/templates/rilheva-modbus-poll/templates) сейчас нет шаблонов для этих устройств.

### Новые файлы

| Файл | Устройство | Описание |
|------|------------|----------|
| `wb-m1w2-button.rilmp` | WB-M1W2 | Вход 1, дискретный режим: состояние, счётчики нажатий |
| `wb-m1w2-temp.rilmp` | WB-M1W2 | Вход 1, 1-Wire: один DS18B20 |
| `wb-mrm2-mini.rilmp` | WB-MRM2-mini v.2 | 2 реле + 2 входа + факт. состояние реле (96–97) |
| `wb-map3et-readings.rilmp` | WB-MAP3ET | U, I, P/Q/S, PF, частота, энергия, настройка ТТ (FW 2.x) |

### Почему отдельные шаблоны

- **M1W2** — разделены на button/temp (минимальный опрос одного входа; режим задаётся в reg 275).
- **MRM2-mini** — ближайший `wb-mr3xx-with-inputs.rilmp` опрашивает **3-е реле** и лишние входы, которых у MRM2-mini нет.
- **MAP3ET** — регистры прошивки 2.x из официальной карты WB; в community шаблона нет.

### Проверка

Протестировано на реальном оборудовании (Modbus RTU через TCP-шлюзы, Rilheva + Home Assistant):

- M1W2 temp/button — OK  
- MRM2-mini relay — OK  
- MAP3ET — подключение и опрос OK  

Источник и полная документация: https://github.com/thebestbaduser/wirenboard-modbus-tcp-homeassistant

### README

В `templates/rilheva-modbus-poll/README.md` добавлена краткая таблица новых шаблонов со ссылками на wiki.
