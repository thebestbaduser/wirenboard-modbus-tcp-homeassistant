# PR в wirenboard/wb-community

Готовый набор для pull request в официальный репозиторий шаблонов Rilheva.

**Цель:** `wirenboard/wb-community` → `templates/rilheva-modbus-poll/`

## Быстрый старт

1. Сделай **Fork** репозитория https://github.com/wirenboard/wb-community  
2. Клонируй свой форк и создай ветку:

```bash
git clone https://github.com/thebestbaduser/wb-community.git
cd wb-community
git checkout -b add-rilheva-m1w2-mrm2-map3et-templates
```

3. Примени файлы из этого каталога:

```bash
bash contrib/wb-community-pr/apply-to-fork.sh
# или из клона wirenboard-modbus-tcp-homeassistant:
bash /path/to/wirenboard-modbus-tcp-homeassistant/contrib/wb-community-pr/apply-to-fork.sh
```

4. Коммит и push:

```bash
git add templates/rilheva-modbus-poll/
git commit -m "Add Rilheva templates for WB-M1W2, MRM2-mini, MAP3ET"
git push -u origin add-rilheva-m1w2-mrm2-map3et-templates
```

5. На GitHub: **New Pull Request** → base: `wirenboard/wb-community` `main`  
   Текст описания — скопируй из [`PR_BODY.md`](PR_BODY.md).

## Содержимое

```
contrib/wb-community-pr/
├── README.md              ← эта инструкция
├── PR_BODY.md             ← готовое описание PR
├── apply-to-fork.sh       ← скрипт копирования в форк
└── templates/rilheva-modbus-poll/
    ├── README.md
    └── templates/
        ├── wb-m1w2-button.rilmp
        ├── wb-m1w2-temp.rilmp
        ├── wb-mrm2-mini.rilmp
        └── wb-map3et-readings.rilmp
```
