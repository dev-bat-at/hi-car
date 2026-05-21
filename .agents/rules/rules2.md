---
trigger: always_on
---

==================================================
AUTOMOTIVE SYSTEM RULES
=======================

Ứng dụng hoạt động trên 3 môi trường:

1. Màn zin
2. Màn độ Android
3. Màn zin + Android Box

==================================================
MÀN ZIN RULES
=============

==================================================
ANDROID PHONE + BLUETOOTH
=========================

Flow:

* Người dùng bật bluetooth điện thoại
* Khi xe khởi động:
  -> Xe tự connect bluetooth với điện thoại
* App detect bluetooth connected
* Delay 5-10 giây
* Auto play lời chào
* Sau khi phát xong:
  -> Auto stop
  -> Release audio focus
  -> Cho phép xe phát nhạc bình thường

Lưu ý:

* Tốc độ bluetooth connect phụ thuộc từng xe
* App phải hỗ trợ custom delay:
  + 1s
  + 3s
  + 5s
  + 10s

  * Custom

==================================================
ANDROID AUTO RULES
==================

Hỗ trợ:

* Android Auto có dây
* Android Auto không dây

Khi Android Auto connect:

* App detect Android Auto session
* Auto play lời chào

Quan trọng:

* Android Auto không ưu tiên app audio thông thường
* Chỉ ưu tiên media app

Do đó:

* App phải hoạt động như media app
* Có MediaSession
* Có foreground playback service
* Có audio focus handling

==================================================
BLUETOOTH + ANDROID AUTO CONFLICT RULES
=======================================

Một số xe:

1. Connect bluetooth trước
2. Sau đó mới chuyển sang Android Auto

Nếu app chỉ detect bluetooth:

* Audio sẽ bị ngắt giữa chừng khi Android Auto activate

Do đó:

* BẮT BUỘC có:

  * Bluetooth flow
  * Android Auto flow

Logic:
IF AndroidAutoConnected:
stop bluetooth flow
switch android auto flow

Không để audio bị interrupt.

==================================================
IPHONE + CARPLAY RULES
======================

Hỗ trợ:

* Carplay wired
* Carplay wireless

Tương lai:

* Architecture phải hỗ trợ mở rộng Carplay flow

==================================================
MÀN ĐỘ ANDROID RULES
====================

Khái niệm:

* Màn thay thế màn zin
* Hoạt động như tablet Android
* Có CH Play
* Có thể cài app trực tiếp

==================================================
MÀN ĐỘ AUTO START RULES
=======================

Đa số màn độ có:

* Application setting
* Auto launch app
* Startup app
* Automatic app setting

Flow:

* Khi xe bật:
  -> Màn Android boot/resume
  -> App tự mở
  -> Auto play audio
  -> Auto close app
  -> Return launcher

==================================================
MÀN ĐỘ HIBERNATE RULES
======================

Có 2 chế độ:

1. Hibernate/Sleep

* Tắt xe -> màn ngủ đông
* Bật xe -> resume ngay
* App hoạt động ổn định nhất

2. Full reboot

* Tắt xe -> màn shutdown
* Bật xe -> boot lại từ đầu
* App hoạt động không ổn định 100%

Quan trọng:

* Với màn độ:
  Boot completed không phải lúc nào cũng play được audio
* Nên ưu tiên:

  * Auto launch app
  * Resume app
  * Foreground service

==================================================
ANDROID BOX RULES
=================

Khái niệm:

* Android box cắm USB màn zin
* Hoạt động như Android mini PC
* Có CH Play
* Có thể boot completed

==================================================
ANDROID BOX FLOW
================

Flow:

* Xe khởi động
* Box reboot
* Android boot completed
* App nhận boot broadcast
* Start foreground service
* Auto play audio ngầm

Ưu điểm:

* Phát ngầm
* Không cần mở app

Nhược điểm:

* Box boot chậm
* Có thể phát trễ

==================================================
KEEP ALIVE RULES
================

Ứng dụng bắt buộc:

* Foreground service
* Wake lock
* Ignore battery optimization
* Notification permission
* Audio permission

Nếu không:

* Android sẽ kill service
* App stop auto play sau thời gian dài

==================================================
FLOATING BUBBLE RULES
=====================

Ứng dụng phải có:

* Floating bubble kiểu Messenger

Bubble gồm:

* Play greeting
* Play goodbye
* Toggle audio

Bubble:

* Drag được
* Có close area
* Luôn giữ sống

Nếu:

* User back app
  -> Bubble hiện

Nếu:

* User mở app
  -> Bubble ẩn

Nếu:

* Clear app
  -> Bubble vẫn tồn tại

==================================================
TARGET DEVICE RULES
===================

Người dùng có thể:

* Chọn bluetooth target device

Ví dụ:

* Điện thoại từng connect 5 xe
* User chọn:
  -> Chỉ xe A mới auto play

Logic:
IF connectedDevice == selectedDevice:
play audio

==================================================
SERVER SYNC RULES
=================

Ứng dụng có:

* Web admin system

App mobile phải:

* Sync audio từ server
* Download audio local
* Cache audio
* Restore offline

==================================================
MAIN PURPOSE
============

Đây KHÔNG phải app audio bình thường.

Đây là:

* Automotive background system
* Bluetooth automation system
* Android Auto audio system
* Foreground media service
* Keep alive system

Ưu tiên:

* Stability
* Auto run
* Keep alive
* Native Android handling
* Foreground service
