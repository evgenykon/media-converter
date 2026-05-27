# Media Converter — TODO

## 1. Project Setup

- [ ] Add dependencies to `pubspec.yaml`:
  - `ffmpeg_kit_extended_flutter` — bundled FFmpeg (macOS + Windows)
  - `flutter_riverpod` — state management
  - `file_picker` — выбор файлов
  - `path_provider` — путь к папке приложения
  - `flutter_local_notifications` — системные уведомления
  - `intl` — форматирование дат/размеров
  - `uuid` — ID для задач
  - `shared_preferences` — настройки
- [ ] `flutter pub get`

## 2. Core

- [ ] `lib/core/theme.dart` — Material Design тема (seed color, light/dark)
- [ ] `lib/core/constants.dart` — константы (форматы, пресеты, лимиты)

## 3. Data

- [ ] `lib/data/presets.json` — вшитые пресеты (видео, аудио, устройства)

## 4. Models

- [ ] `lib/models/media_file.dart` — информация о файле (путь, размер, кодек, разрешение, duration)
- [ ] `lib/models/preset.dart` — пресет (имя, категория, контейнер, кодеки, битрейты, разрешение)
- [ ] `lib/models/conversion_job.dart` — задача конвертации (input → preset → output + статус + прогресс)

## 5. Services

- [ ] `lib/services/ffmpeg_service.dart` — запуск/отмена/прогресс конвертации через ffmpeg_kit
- [ ] `lib/services/media_info_service.dart` — получение метаданных через ffprobe
- [ ] `lib/services/history_service.dart` — CRUD истории в JSON-файл (path_provider)
- [ ] `lib/services/notification_service.dart` — системные уведомления (flutter_local_notifications)

## 6. Providers

- [ ] `lib/providers/conversion_provider.dart` — список задач (активные + история), запуск, отмена
- [ ] `lib/providers/settings_provider.dart` — настройки (тема, уведомления, дефолтная директория)

## 7. Screens

- [ ] `lib/screens/home_screen.dart` — кнопка "Конвертировать" + список истории конвертаций

## 8. Widgets

- [ ] `lib/widgets/preset_modal.dart` — bottom sheet с пресетами + сравнительная таблица + кнопка "Старт"
- [ ] `lib/widgets/preset_tile.dart` — строка пресета в списке
- [ ] `lib/widgets/comparison_table.dart` — таблица: исходник vs результат
- [ ] `lib/widgets/file_info_card.dart` — инфо о файле (иконка, имя, размер, кодек)
- [ ] `lib/widgets/progress_section.dart` — прогресс конвертации (бар + скорость + ETA)
- [ ] `lib/widgets/job_tile.dart` — карточка в истории (статус, иконка, время, размер)
- [ ] `lib/widgets/empty_state.dart` — пустое состояние (нет истории)

## 9. App & Entry

- [ ] `lib/app.dart` — MaterialApp с маршрутами и провайдерами
- [ ] `lib/main.dart` — точка входа, инициализация сервисов (уведомления, загрузка истории)

## 10. History Persistence

- [ ] Файл истории: `{getApplicationSupportDirectory()}/conversion_history.json`
- [ ] Загрузка при старте приложения
- [ ] Автосохранение после каждого изменения
- [ ] Сериализация/десериализация ConversionJob в JSON

## 11. System Notifications

- [ ] Настройка `flutter_local_notifications` для macOS и Windows
- [ ] Уведомление об успешном завершении конвертации
- [ ] Уведомление об ошибке
- [ ] Toggle в настройках (вкл/выкл)

## 12. Polish

- [ ] Пустое состояние на главном экране
- [ ] Обработка ошибок (ffmpeg не найден, файл не выбран, конвертация упала)
- [ ] Отмена конвертации
- [ ] Оценка размера результирующего файла
- [ ] Lottie-анимации или кастомные иконки (опционально)
- [ ] `flutter analyze` — чистый проход
- [ ] `flutter test` — базовые тесты

---

## Legend

- `[ ]` — todo
- `[x]` — done
