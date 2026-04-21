# 📻 RadioMD

![Flutter](https://img.shields.io/badge/Flutter-3.24+-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.5+-0175C2?logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-lightgrey)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**RadioMD** — современное мобильное приложение для прослушивания интернет-радиостанций.  
Приложение создано для удобного и стабильного прослушивания любимых станций: в фоновом режиме, с управлением воспроизведением через экран блокировки и с быстрым доступом к избранному.

<p align="center">
  <img src="https://storage.googleapis.com/cms-storage-bucket/0dbfcc7a59cd1cf16282.png" alt="RadioMD Preview" width="200"/>
</p>

---

## Возможности

- **Каталог станций** — встроенный список популярных радиостанций с удобным поиском.
- **Избранное** — сохранение любимых станций для быстрого доступа.
- **Фоновое воспроизведение** — музыка продолжает играть даже при свёрнутом приложении.
- **Тёмная тема** — поддержка светлого и тёмного оформления.
- **Пуш-уведомления** — короткие системные сообщения и уведомления.
- **Управление с экрана блокировки** — быстрый доступ к плееру без открытия приложения.

---

## Скриншоты

![Главный экран](https://storage.googleapis.com/cms-storage-bucket/0dbfcc7a59cd1cf16282.png)  ![Плеер](https://storage.googleapis.com/cms-storage-bucket/0dbfcc7a59cd1cf16282.png)  ![Избранное](https://storage.googleapis.com/cms-storage-bucket/0dbfcc7a59cd1cf16282.png)  ![Рекомендации](https://storage.googleapis.com/cms-storage-bucket/0dbfcc7a59cd1cf16282.png) 

---

## Технологический стек

- **Flutter** — кроссплатформенная разработка интерфейсов.
- **Dart** — основной язык разработки.
- **just_audio** — воспроизведение аудиопотока.
- **audio_service** — работа с фоновым аудио и системными медиа-контроллерами.
- **Provider / Riverpod** — управление состоянием приложения.
- **Hive / SharedPreferences** — локальное хранение пользовательских данных и избранного.
- **Firebase** — уведомления и backend-интеграции.
- **PostgreSQL** — база данных.
- **Figma** — проектирование интерфейса.

---

## Предварительные требования

Перед запуском проекта убедитесь, что у вас установлены:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable-версия)
- Android Studio / Xcode
- Эмулятор Android / iOS или реальное устройство
- VS Code / Android Studio / IntelliJ IDEA

---

## Установка и запуск

```bash
git clone https://github.com/ScholoxowMaxim/RadioMD.git
cd RadioMD
