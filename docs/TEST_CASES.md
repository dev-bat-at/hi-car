# Test Cases — Box Mode & Bug Report

## Prerequisites

- App installed, logged in, mode **Android Box**
- Greeting audio selected (`boot_greeting.mp3` synced via opening app once)
- Auto-play enabled
- Use **fvm**: `fvm flutter run` / `fvm flutter test`

---

## Box boot (P0)

| ID | Steps | Expected |
|----|-------|----------|
| B1 | Power off device 2–5 min → power on (repeat ×3) | Greeting plays once per boot after ≥5s delay |
| B2 | Simulate failed early boot: send `LOCKED_BOOT` then `BOOT_COMPLETED` via adb (see below) | Second broadcast retries if first play did not start |
| B3 | Manual play button works after boot | Audio plays via UI |
| B4 | Manual play + auto boot same session | No duplicate auto play after manual |

### adb helpers (Box mode)

```bash
# Trigger boot flow manually (device must be in android_box_mode + logged in)
adb shell am broadcast -a android.intent.action.BOOT_COMPLETED -p com.hicar.ora.limited

# View in-app diagnostic log (same format as Settings preview)
adb shell run-as com.hicar.ora.limited cat files/hicar_diagnostic.log
```

---

## Bug report (P1)

| ID | Steps | Expected |
|----|-------|----------|
| BUG1 | Cause a `native_error` (e.g. disconnect network + trigger sync error) → Settings → Báo cáo lỗi | Error listed; send sheet shows note field + adb E/W block |
| BUG2 | Send report with note | API body includes `device_id`, `device_name`, `device_model`, `os_version`, `app_version`, `sync_status`, `description` (note + adb log) |
| BUG3 | No errors recorded | Dialog shows “Chưa ghi nhận lỗi nào” |

---

## Regression (quick)

| ID | Mode | Expected |
|----|------|----------|
| R1 | Android Auto | Unchanged (no boot auto-play from Box path) |
| R2 | Logout | BootReceiver skip — no auto play |

---

## Phone vs Box

Phone **power off 2–5 minutes** in Box mode is the closest simulation to box shutdown. Fast reboot alone is insufficient for cold-boot timing tests.
