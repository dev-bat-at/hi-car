---
description: WORKFLOW V1
---

# GIỌNG THƯƠNG GIA - WORKFLOW

==================================================
APP FLOW
========

1. SplashScreen

* Kiểm tra login token
* Kiểm tra permission
* Khởi tạo foreground service
* Restore overlay nếu cần

Nếu chưa login:
-> LoginScreen

Nếu đã login:
-> HomeScreen

==================================================
AUTH FLOW
=========

LOGIN:

* Nhập số điện thoại
* Nhập password
* Login success
  -> HomeScreen

SIGNUP:

* Nhập số điện thoại
* Nhập tên
* Nhập password
* Nhập biển số xe

Signup success:
-> GenAudioScreen

==================================================
GEN AUDIO FLOW
==============

1. User nhập:

* Tên chủ xe
* Biển số xe
* Hãng xe

2. Nhấn Generate

3. Hệ thống:

* Kiểm tra lượt generate
* Nếu còn lượt:
  -> Gen demo audio
  -> Hiển thị player
* Nếu hết lượt:
  -> Dialog hết lượt

4. User:

* Nghe demo
* Set làm lời chào
* Set làm lời tạm biệt
* Gửi admin

==================================================
HOME FLOW
=========

HOME gồm:

* User info
* Nút phát lời chào
* Nút phát tạm biệt
* Playback controller
* Audio list
* Bluetooth devices
* Permission status

==================================================
SETTINGS FLOW
=============

Settings:

* Gen Audio
* Gửi bug
* Xóa tài khoản
* Đăng xuất

==================================================
OVERLAY FLOW
============

Khi app:

* Back app
* Background app

=> Hiện overlay bubble

Overlay gồm:

* Phát lời chào
* Phát lời tạm biệt
* Toggle âm thanh

Khi mở app:
=> Overlay tự ẩn

Nếu clear app:
=> Overlay vẫn tồn tại

==================================================
BLUETOOTH FLOW
==============

1. Xe khởi động
2. Bluetooth connect
3. App detect device
4. So khớp thiết bị user chọn
5. Delay
6. Auto play lời chào
7. Auto stop
8. Release audio focus

==================================================
ANDROID AUTO FLOW
=================

1. Detect Android Auto
2. Nếu bluetooth đang phát:
   -> stop bluetooth flow
3. Chuyển sang Android Auto flow
4. Play audio
5. Auto stop

==================================================
BOOT COMPLETED FLOW
===================

Khi:

* Điện thoại restart
* Android box restart

Hệ thống:

* Start foreground service
* Restore overlay
* Restore audio config
* Keep alive app

==================================================
MÀN ĐỘ FLOW
===========

Khi màn hình khởi động:

* Auto launch app
* Auto play audio
* Auto close app
* Return home launcher

==================================================
ANDROID BOX FLOW
================

Khi boot completed:

* Box restart
* App nhận boot receiver
* Start service
* Auto play ngầm

==================================================
AUDIO FLOW
==========

1. Detect event
2. Delay
3. Play audio
4. Auto stop
5. Release focus
6. Cho phép xe phát nhạc tiếp

==================================================
PERMISSION FLOW
===============

Yêu cầu:

* Overlay permission
* Notification permission
* Bluetooth permission
* Battery optimization bypass
* Audio permission

Nếu thiếu:
-> Hiện dialog hướng dẫn cấp quyền
