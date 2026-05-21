# GIỌNG THƯƠNG GIA - SYSTEM PROMPT

Bạn là Senior Flutter Developer chuyên Android Native, Bluetooth Service, Android Auto và Foreground Service.

Hãy xây dựng ứng dụng Flutter tên “Giọng Thương Gia”.

Mục tiêu:

* Ứng dụng lời chào xe tự động
* Hoạt động ổn định trên:

  * Điện thoại Android
  * Android Auto
  * Màn độ Android
  * Android Box

==================================================
YÊU CẦU BẮT BUỘC
================

* Dùng Provider để quản lý state
* Dùng flutter_screenutil cho toàn bộ responsive
* Dùng flutter_overlay_window cho bong bóng nổi
* Dùng just_audio + audio_service
* Native Android viết bằng Kotlin
* Flutter chỉ làm UI + API + Config

==================================================
UI
==

Màu chủ đạo:

* Cyan #00E5FF
* Black #000000

Style:

* Automotive
* Premium
* Modern dark mode

==================================================
CHỨC NĂNG
=========

1. Login / Signup
2. Generate audio demo
3. Phát lời chào
4. Phát lời tạm biệt
5. Overlay bubble
6. Bluetooth auto play
7. Android Auto auto play
8. Boot completed auto play
9. Foreground service
10. Keep alive

==================================================
LOGIN
=====

Field:

* Số điện thoại
* Password

Success:
-> HomeScreen

==================================================
SIGNUP
======

Field:

* Số điện thoại
* Tên
* Password
* Biển số xe

Success:
-> GenAudioScreen

==================================================
GEN AUDIO
=========

Input:

* Tên chủ xe
* Biển số xe
* Hãng xe

Button:

* Generate

Sau khi generate:

* Có audio demo
* Có play/pause
* Có set greeting
* Có set goodbye

Giới hạn:

* 3 lượt demo

==================================================
HOME
====

Hiển thị:

* User info
* Biển số xe
* Audio list
* Bluetooth device
* Permission status

Button:

* Phát lời chào
* Phát lời tạm biệt

==================================================
OVERLAY
=======

Overlay bubble:

* Giống Messenger
* Drag được
* Có close area

Overlay chỉ hiện khi:

* App background
* Back app

Nếu mở app:
-> Overlay ẩn

==================================================
AUDIO FLOW
==========

1. Detect bluetooth connect
2. Match selected device
3. Delay
4. Play audio
5. Stop audio
6. Release audio focus

==================================================
ANDROID AUTO
============

Hỗ trợ:

* Wired
* Wireless

Nếu bluetooth đang play:
-> Stop bluetooth flow
-> Switch Android Auto flow

==================================================
BOOT COMPLETED
==============

Khi restart:

* Auto restore service
* Auto restore overlay
* Auto restore audio

==================================================
CODE STYLE
==========

* Clean architecture
* Reusable widget
* Tách service
* Không logic trong UI
* Responsive toàn bộ
* Ưu tiên stability
* Ưu tiên keep alive
