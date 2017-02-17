# Broadcom Bluetooth firmware for Linux kernel

## Overview
This package intentended to provide firmware of Broadcom WIDCOMM® Bluetooth devices (including BCM20702, BCM20703, BCM43142 chipsets and other) for Linux kernel. Since Febriary 2017, Broadcom ships they drivers directly to Windows Update service. They can be [downloaded here](http://www.catalog.update.microsoft.com/Search.aspx?q=Broadcom+bluetooth).

## Detection and Installation

When you inserting Broadcom Bluetooth device you prefered Linux distribution may not load it properly:

```
Bluetooth: hci1: BCM: chip id 63
Bluetooth: hci1: BCM20702A
Bluetooth: hci1: BCM20702A1 (001.002.014) build 0000
bluetooth hci1: Direct firmware load for brcm/BCM20702A1-0b05-17cb.hcd failed with error -2
Bluetooth: hci1: BCM: Patch brcm/BCM20702A1-0b05-17cb.hcd not found
```

As you can see, you need `brcm/BCM20702A1-0b05-17cb.hcd` firmware.

Place required `.hcd` file to `/lib/firmware/brcm`. After inserting Broadcom Bluetooth device you will see that firmware successfully loaded:

```
Bluetooth: hci1: BCM: chip id 63
Bluetooth: hci1: BCM20702A
Bluetooth: hci1: BCM20702A1 (001.002.014) build 0000
Bluetooth: hci1: BCM20702A1 (001.002.014) build 1467
Bluetooth: hci1: Broadcom Bluetooth Device
```

Congratulations, now your bluetooth device successfully loaded. Now go to Bluez for futher configuration.

## License

Firmware files are licensed under [Broadcom WIDCOMM Bluetooth Software License Agreement](LICENSE.broadcom_bcm20702).
Other parts of project are licensed under standard [MIT license](LICENSE.MIT.txt).

## Supported devices

See [DEVICES file](DEVICES.md).
