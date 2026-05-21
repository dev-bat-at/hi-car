---
trigger: always_on
---

# GIỌNG THƯƠNG GIA - RULES

==================================================
TECH STACK RULES
================

* Flutter latest stable
* Kotlin native Android
* Provider + ChangeNotifier
* go_router
* flutter_screenutil
* just_audio
* audio_service
* flutter_overlay_window
* dio
* shared_preferences
* flutter_blue_plus

==================================================
UI RULES
========

Màu chủ đạo:

* #00E5FF
* #000000

Style:

* Automotive
* Premium dark mode
* Modern
* Cyan glow

==================================================
SCREENUTIL RULES
================

BẮT BUỘC:

* width -> .w
* height -> .h
* fontSize -> .sp
* radius -> .r

KHÔNG hardcode size.

==================================================
ARCHITECTURE RULES
==================

Folder structure:

lib/
├── core/
├── data/
├── providers/
├── screens/
├── native/
├── assets/

==================================================
PROVIDER RULES
==============

Tách riêng:

* AuthProvider
* AudioProvider
* BluetoothProvider
* OverlayProvider
* SettingsProvider
* PermissionProvider

Không viết logic trong UI.

==================================================
CODE RULES
==========

* Clean code
* Reusable widget
* Không duplicate
* Widget nhỏ
* Tách service
* Tách repository

==================================================
NATIVE RULES
============

Kotlin bắt buộc xử lý:

* BootReceiver
* BluetoothReceiver
* ForegroundService
* Android Auto detect
* MediaSession

Flutter chỉ là:

* UI
* API
* Config
* State management

==================================================
OVERLAY RULES
=============

Dùng:
flutter_overlay_window

Overlay:

* Messenger style
* Drag được
* Có close area
* Animation mượt

==================================================
KEEP ALIVE RULES
================

Ứng dụng phải:

* Chạy foreground service
* WakeLock
* Ignore battery optimization

Không được chết service.

==================================================
ANDROID PERMISSION RULES
========================

<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE" />
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />

==================================================
AUDIO RULES
===========

* Auto play
* Auto stop
* Release audio focus
* Không chồng audio
* Hỗ trợ bluetooth + Android Auto

==================================================
ANDROID AUTO RULES
==================

Hỗ trợ:

* Wired Android Auto
* Wireless Android Auto

Nếu bluetooth flow đang chạy:
-> Chuyển sang Android Auto flow

==================================================
ASSETS RULES
============

assets/

* audio/
* images/
* fonts/

App title:
Giọng Thương Gia
