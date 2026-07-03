# Latifa's Great Birthday — Gatsby Invitation

Одностраничный веб-пригласительный в стиле «Великий Гэтсби» (арт-деко, золото/серебро/чёрный).
Дата события: **12.07.2026**, место: **Miras, Ташкент**.

Чистый HTML/CSS/JS в одном файле. Без сборки, без зависимостей, без фреймворков.

## Быстрый старт

```bash
# вариант 1: просто открыть index.html в браузере

# вариант 2: локальный сервер (нужен для теста музыки на некоторых браузерах)
npx serve .
# или
python3 -m http.server 8000
```

Проверять обязательно в мобильной ширине (~380px) — приглашение рассылается через Telegram.

## Деплой

Netlify Drop: перетащить **папку целиком** (index.html + og-image.png + **atmos.mp4** + music.mp3) на https://app.netlify.com/drop.
`atmos.mp4` — фоновое видео секции «Атмосфера» (обязательно рядом; если его нет, покажется статичный кадр-постер). `music.mp3` опционально.

## Структура

```
latifa-invitation/
├── index.html                      # весь сайт: разметка + стили + скрипты (текстуры — inline SVG data-URI)
├── atmos.mp4                       # фоновое видео секции «Атмосфера» (налив шампанского; деплоить рядом)
├── og-image.png                    # превью 1200×630 для Telegram/WhatsApp (деплоить рядом с index.html)
├── assets/
│   ├── atmos-duotone.jpg           # дуотон-исходник «Атмосферы вечера» (вшит в index.html как base64)
│   ├── dresscode-her-duotone.jpg   # дуотон образа For Her (вшит в index.html)
│   ├── dresscode-him-duotone.jpg   # дуотон образа For Him (вшит в index.html)
│   ├── ladies.png / gentlemen.png  # старые клипарт-иллюстрации (не используются)
│   └── source/
│       ├── atmos-photo-credit.txt  # Pexels ID и лицензии всех фото
│       └── reference-invitation.jpg# дизайн-референс (печатное приглашение)
├── CLAUDE.md                       # память проекта для Claude Code (читать первым!)
├── .cursorrules                    # правила для Cursor (ссылается на CLAUDE.md)
└── README.md
```

`assets/` в деплой не нужен — это исходники на случай доработок.

## Как устроена страница

Интро «Black Velvet × Champagne Gold» (WebGL-бархат: свет проходит по ткани → золотое тиснение LATIFA → OPEN THE INVITATION → имя растворяется в золотую пыль, переход через «дымчатое стекло») → Экран-афиша с очень крупной датой «12 JULY 2026», MIRAS и countdown одной строкой → Атмосфера вечера (полноэкранное фото в дуотоне + фраза) → Dress code как fashion-галерея (образы For Her / For Him) → Финал (тёмный экран с дымом и золотыми бликами, «A little party never killed nobody» · See you · 12.07.2026) → футер. Музыка стартует по клику на OPEN THE INVITATION, кнопка вкл/выкл — справа внизу. Для интро подключены Three.js и GSAP с CDN; без них (или с reduced-motion) интро работает в упрощённом статичном режиме.

## Что кастомизировать

| Что | Где в index.html |
|---|---|
| Время начала (countdown) | константа `EVENT_DATE` в начале `<script>` |
| Время/адрес на экране-афише | строка `.s2-city` (см. комментарий «Адрес зала и время») |
| Фото образов дресс-кода | блоки `<!-- ОБРАЗ ДЛЯ ... -->`, поменять `src` у `<img>` внутри `.look-photo` |
| Музыка | положить `music.mp3` рядом с index.html (см. блок `<!-- ===== МУЗЫКА -->`) |
| Текст кнопки входа | `#enterBtn` (сейчас `Open the invitation`) |
| Приём RSVP | константа `RSVP_FORM` (URL Apps Script) в `<script>` (см. раздел «RSVP» ниже) |
| Цвета и шрифты | CSS-переменные в `:root` |

## RSVP — встроенная форма → Google Таблица (Apps Script)

В финале уже встроена форма: гость вводит **имя**, выбирает **«I'll be there / Can't make it»** и жмёт «Send RSVP» — ответ уходит прямо в Google Таблицу, не покидая страницы. Бэкенда нет, всё в `index.html`; приёмная сторона — маленький скрипт Apps Script на самой таблице (без Google Формы).

Схема: форма шлёт `POST` с полями `name` и `attend` (`Да`/`Нет`) на URL веб-приложения Apps Script; скрипт `doPost` дописывает в таблицу строку **Дата · Имя · Присутствие**.

**1. Создай таблицу.** Новая Google Таблица (напр. «Latifa RSVP»). Шапку вписывать не обязательно — скрипт сам поставит её (`Дата · Имя · Придёт`) и закрепит при первом ответе, если лист пустой. Названия колонок на работу не влияют (скрипт пишет по позициям A/B/C).

**2. Вставь скрипт.** В таблице → **Расширения → Apps Script**, удали заготовку, вставь:
   ```javascript
   function doPost(e) {
     try {
       var sheet = SpreadsheetApp.getActiveSpreadsheet().getSheets()[0];
       ensureHeader(sheet);                     // при первом ответе на пустом листе: шапка + закрепление
       var name   = (e && e.parameter && e.parameter.name)   || '';
       var attend = (e && e.parameter && e.parameter.attend) || '';
       var stamp = Utilities.formatDate(new Date(), 'Asia/Tashkent', 'dd.MM.yyyy HH:mm');
       sheet.appendRow([stamp, name, attend]);
       return ContentService.createTextOutput(JSON.stringify({ ok: true }))
         .setMimeType(ContentService.MimeType.JSON);
     } catch (err) {
       return ContentService.createTextOutput(JSON.stringify({ ok: false, error: String(err) }))
         .setMimeType(ContentService.MimeType.JSON);
     }
   }

   // Шапка + жирный + закрепление строки 1 — только если лист пустой (не трёт ответы).
   function ensureHeader(sheet) {
     if (sheet.getLastRow() > 0) return;
     sheet.getRange('A1:C1').setValues([['Дата', 'Имя', 'Придёт']]).setFontWeight('bold');
     sheet.setFrozenRows(1);
   }

   // Ручная настройка листа: запусти ОДИН раз из редактора (выбрать setupSheet → ▶ Выполнить),
   // если хочешь оформить таблицу сразу, не дожидаясь первого ответа.
   function setupSheet() {
     var sheet = SpreadsheetApp.getActiveSpreadsheet().getSheets()[0];
     sheet.getRange('A1:C1').setValues([['Дата', 'Имя', 'Придёт']]).setFontWeight('bold');
     sheet.setFrozenRows(1);
   }
   ```

**3. Опубликуй как веб-приложение.** **Развернуть → Новое развёртывание** → ⚙️ тип **«Веб-приложение»** (именно оно, не «Библиотека») → **Запуск от имени:** Я, **У кого есть доступ:** **Все** → **Развернуть** → пройди авторизацию (Дополнительно → Разрешить, приложение твоё). Скопируй **URL веб-приложения** — вида `https://script.google.com/macros/s/AKfyc…/exec` (обязательно `/macros/s/…/exec`, а не `/macros/library/…`).

**4. Впиши URL** в `index.html` (блок `RSVP → GOOGLE ТАБЛИЦА (Apps Script)`):
   ```js
   var RSVP_FORM = 'https://script.google.com/macros/s/AKfyc…/exec'; // ← URL веб-приложения
   var RSVP_YES  = 'Да';   // текст в колонке «Присутствие» для «буду»
   var RSVP_NO   = 'Нет';  // текст для «не смогу»
   ```

Пока `RSVP_FORM` не начинается с `http`, форма при отправке покажет ошибку и подсказку в консоли (данные не уйдут). Тексты формы переведены EN/RU (ключи `rsvp*` в словаре внизу файла). Проверить: заполни, отправь — в Google Таблице появится строка.

**Отладка деплоя** (если строки не приходят):
- URL должен быть `/macros/s/…/exec`. Если это `/macros/library/…` — выбран тип «Библиотека», пересоздай как «Веб-приложение».
- «У кого есть доступ» = **Все** (не «Только я» и не «Все с аккаунтом Google»).
- Правил код после публикации? Деплой заморожен на старой версии — **Управление развёртываниями → ✏️ → Версия: Новая версия → Развернуть**.
- Проверка из терминала: `curl -sS -X POST -d "name=Тест&attend=Да" '…/exec' -D - -o /dev/null` — первый ответ **302** (редирект на `/macros/echo`) означает, что `doPost` отработал и строка записалась; `lib=` в адресе редиректа безвреден.

## TODO

- [x] Время начала подтверждено: 18:30 (`EVENT_DATE`)
- [ ] Точный адрес Miras + ссылка на Яндекс.Карты/2GIS в карточку Where
- [ ] `music.mp3` — тихий джаз 1920-х, royalty-free (pixabay.com/music: «1920s jazz», «swing»)
- [ ] Прогнать на реальном телефоне с увеличенным системным шрифтом (баг уже чинили — регресс-чек)
- [ ] После деплоя вписать абсолютный URL og-image в `<meta property="og:image">` (сейчас относительный)
- [ ] Реальные фото дресс-кода в золотом дуотоне вместо типографских слотов (по желанию)
- [x] RSVP → Google Таблица через Apps Script: скрипт опубликован, `RSVP_FORM` вписан, отправка проверена (см. раздел «RSVP» выше)

Бэклог идей: кнопка «Add to calendar» (.ics).
