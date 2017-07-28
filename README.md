# Broadcom Bluetooth firmware for Linux kernel

## Overview
This package intentended to provide firmware of Broadcom WIDCOMM® Bluetooth
devices (including BCM20702, BCM20703, BCM43142 chipsets and other) for Linux
kernel. Since February 2017, Broadcom ships their drivers directly to Windows
Update service. They can be [downloaded here](http://www.catalog.update.microsoft.com/Search.aspx?q=Broadcom+bluetooth).

## Detection and Installation

When you inserting Broadcom Bluetooth device you prefered Linux distribution
may not load it properly:

```
Bluetooth: hci1: BCM: chip id 63
Bluetooth: hci1: BCM20702A
Bluetooth: hci1: BCM20702A1 (001.002.014) build 0000
bluetooth hci1: Direct firmware load for brcm/BCM20702A1-0b05-17cb.hcd failed with error -2
Bluetooth: hci1: BCM: Patch brcm/BCM20702A1-0b05-17cb.hcd not found
```

As you can see, you need `brcm/BCM20702A1-0b05-17cb.hcd` firmware.

Place required `.hcd` file to `/lib/firmware/brcm`. After inserting Broadcom
Bluetooth device you will see that firmware successfully loaded:

```
Bluetooth: hci1: BCM: chip id 63
Bluetooth: hci1: BCM20702A
Bluetooth: hci1: BCM20702A1 (001.002.014) build 0000
Bluetooth: hci1: BCM20702A1 (001.002.014) build 1467
Bluetooth: hci1: Broadcom Bluetooth Device
```

Congratulations, now your bluetooth device successfully loaded. Now go to Bluez
for futher configuration.

## Incorrect names for devices

There may be incorrect naming between presented firmware name and name
requested from Linux kernel. For example, system may request `BCM4354A2-13d3-3485.hcd`
but actually this is `BCM4356A2-13d3-3485.hcd`. This is happens because
incorrect naming in Linux kernel. Just rename file to name that need to
kernel. Here quick naming convertion:

| Original name | Requested by Linux |
|---------------|--------------------|
| BCM4356A2     | BCM4354A2          |

## Notes about combined WiFi+Bluetooth devices

Some Bluetooth controller (for example, BCM4354 and BCM4356) are integrated to
WiFi chipset (this can be BCM43XX 802.11ac Wireless Network Adapter or just
simple generic Broadcom PCIE Wireless). These devices requires two kinds of
firmware - first for WiFi, and second for Bluetooth. Without WiFi firmware
Bluetooth will not initialize and [will not work properly](https://github.com/winterheart/broadcom-bt-firmware/issues/3#issuecomment-318512097).
Firmware for WiFi already included to kernel, but you may need to do additional
work to [place correct NVRAM](https://wireless.wiki.kernel.org/en/users/drivers/brcm80211#broadcom_brcmfmac_driver).

Here example how it can looks (note about `brcm/brcmfmac4356-pcie.txt` 
loading - this is your customized NVRAM):

```
usbcore: registered new interface driver brcmfmac
brcmfmac 0000:02:00.0: firmware: direct-loading firmware brcm/brcmfmac4356-pcie.bin
brcmfmac 0000:02:00.0: firmware: direct-loading firmware brcm/brcmfmac4356-pcie.txt
Bluetooth: hci0: BCM: chip id 101
Bluetooth: hci0: N360-11
Bluetooth: hci0: BCM4354A2 (001.003.015) build 0000
bluetooth hci0: firmware: direct-loading firmware brcm/BCM4354A2-13d3-3485.hcd
```

## License

Firmware files are licensed under [Broadcom WIDCOMM Bluetooth Software License Agreement](LICENSE.broadcom_bcm20702).
Other parts of project are licensed under standard [MIT license](LICENSE.MIT.txt).

## Supported devices

See [DEVICES file](DEVICES.md).

