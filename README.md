# hypr

Конфиг Hyprland для Arch/CachyOS с NVIDIA. Минималистичный: без блюра, теней,
скруглений и анимаций — всё ради отзывчивости.

Стек: **hyprland + waybar + wofi + kitty + mako**.

> Конфиг написан на **Lua**. С Hyprland 0.55 hyprlang объявлен устаревшим,
> и основной файл теперь `~/.config/hypr/hyprland.lua`.
> Документация: <https://wiki.hypr.land/Configuring/Start/>

## Установка

```bash
git clone <этот-репозиторий> ~/dotfiles
cd ~/dotfiles

./install.sh --dry-run              # посмотреть, что будет сделано
./install.sh --packages --nvidia    # поставить пакеты и разложить конфиги
```

`install.sh` создаёт симлинки из `config/*` в `~/.config/`. Всё, что там уже
лежало, переносится в `<имя>.bak.<дата>` — ничего не удаляется молча.
Повторный запуск безопасен: существующие правильные симлинки не трогаются.

Флаги: `--dry-run` (`-n`), `--packages`, `--nvidia`, `--help`.

### После установки

1. Перезагрузиться и убедиться, что DRM modesetting включён:
   ```bash
   cat /sys/module/nvidia_drm/parameters/modeset   # должно вывести Y
   ```
2. Запустить сессию из tty: `start-hyprland`
3. Прописать свои мониторы в `config/hypr/conf/monitors.lua`
   (`hyprctl monitors all` покажет имена выходов и режимы).

Конфиг перечитывается в момент сохранения файла. Вручную — `hyprctl reload`,
список претензий Hyprland — `hyprctl configerrors`.

Если конфиг сломан, Hyprland оставляет аварийные биндов:
`SUPER+Q` — терминал, `SUPER+R` — запуск, `SUPER+M` — выход.

## Структура

```
config/hypr/hyprland.lua      точка входа, только require()
config/hypr/conf/
    env.lua                   переменные окружения, блок NVIDIA
    monitors.lua              мониторы
    look.lua                  внешний вид, палитра, анимации
    input.lua                 клавиатура (us,ru), мышь, тачпад
    rules.lua                 правила окон и слоёв
    keybinds.lua              все биндов
    autostart.lua             что запускается со стартом сессии
config/{waybar,wofi,kitty,mako}/
install.sh                    симлинки + пакеты
packages/                     списки пакетов для pacman
tests/check.lua               офлайн-проверка конфига
```

Каждый `require()` — отдельная Lua-область видимости: ошибка в одном файле
не мешает загрузиться остальным.

Локальные правки под конкретную машину можно положить в
`~/.config/hypr/local.lua` — он подключается последним и не отслеживается git.

## Клавиши

`SUPER` — основной модификатор.

| Клавиши | Действие |
| --- | --- |
| `SUPER + Return` | терминал (kitty) |
| `SUPER + R` | лаунчер (wofi) |
| `SUPER + Q` / `SUPER + SHIFT + Q` | закрыть окно / убить процесс |
| `SUPER + M` | выйти из Hyprland |
| `SUPER + V` | плавающий режим |
| `SUPER + F` / `SUPER + SHIFT + F` | фуллскрин / максимизация |
| `SUPER + C` | центрировать окно |
| `SUPER + J` | сменить направление сплита |
| `SUPER + h/j/k/l`, стрелки | фокус |
| `SUPER + SHIFT + h/j/k/l` | переместить окно |
| `SUPER + Tab` | предыдущее окно |
| `SUPER + 1..0` | рабочий стол |
| `SUPER + SHIFT + 1..0` | перенести окно на рабочий стол |
| `SUPER + колесо` | листать рабочие столы |
| `SUPER + S` / `SUPER + SHIFT + S` | скретчпад |
| `SUPER + ЛКМ` / `SUPER + ПКМ` | двигать / растягивать мышью |
| `SUPER + ALT + R` | режим ресайза (выход — `Esc`) |
| мультимедиа-клавиши | громкость, микрофон, яркость, плеер |

Раскладка переключается `Alt + Shift` (`us` ⇄ `ru`).

## Проверка конфига без Hyprland

```bash
lua tests/check.lua
```

Скрипт подменяет глобальный `hl` заглушкой, повторяющей документированный API,
и исполняет конфиг. Ловит синтаксические ошибки, несуществующие функции
`hl.*`, неизвестные диспатчеры и неизвестные секции конфига. Значения
отдельных опций он не проверяет — это умеет только сам Hyprland.

## NVIDIA

Нужны только две переменные окружения (`conf/env.lua`):
`LIBVA_DRIVER_NAME=nvidia` и `__GLX_VENDOR_LIBRARY_NAME=nvidia`.
Плюс `ELECTRON_OZONE_PLATFORM_HINT=auto` — от мерцания Electron-приложений.

Старые гайды советуют `GBM_BACKEND`, `WLR_NO_HARDWARE_CURSORS` и
`XDG_SESSION_TYPE` — сейчас это устарело, добавлять их обратно не нужно.

`nvidia_drm modeset=1` на Arch включён из коробки. Если курсор мигает или
пропадает — раскомментировать `no_hardware_cursors` в `conf/look.lua`.

Подробности: <https://wiki.hypr.land/Nvidia/>

## Что дальше

Заготовки уже лежат закомментированными в конфигах:

- `hyprlock` + `hypridle` — блокировка экрана и автоблокировка
- `hyprpaper` — обои
- `grim` + `slurp` — скриншоты (биндов на `Print` в `keybinds.lua`)
- `cliphist` — история буфера обмена
- быстрый пресет анимаций — в конце `conf/look.lua`
