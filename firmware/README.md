# ESP-IDF firmware bootstrap

The project's sole software developer owns firmware source changes. The hardware support member supplies exact part numbers, datasheets, measured electrical information, and photographs; these facts are reviewed before any pin assignment or driver implementation.

This is an ESP-IDF starter for an ESP32 target. It initializes NVS and reports that hardware integration is pending. It intentionally does not assign GPIO pins, read sensors, drive actuators, initialize Wi-Fi, or operate an LTE modem.

## Build on Windows

Use the ESP-IDF terminal installed by Espressif Installation Manager. Confirm the exact ESP32 family first. If the actual board is an ESP32-S3, then:

```powershell
cd path\to\smart-aquarium-starter\firmware
idf.py set-target esp32s3
idf.py build
```

Connect a data-capable USB cable and check the actual COM port in Device Manager before flashing:

```powershell
idf.py -p COMx flash monitor
```

## Before adding hardware drivers

Create a hardware inventory with exact manufacturer, model/revision, supply voltage, peak current, logic output voltage, interface, calibration method, and source datasheet. Then prepare a verified pin map from the exact board schematic. Never power an LTE modem from the ESP32 3V3 pin without a verified power design. Do not energize pump/feeder loads until the driver ratings, power path, protection, isolation, and safe boot behavior are reviewed.
