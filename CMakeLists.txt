cmake_minimum_required(VERSION 3.11)
project(broadcom-bt-firmware
	VERSION 10.1.0.1115
	DESCRIPTION "Firmware for Broadcom Bluetooth devices"
	HOMEPAGE_URL "https://github.com/winterheart/broadcom-bt-firmware"
	LANGUAGES NONE
)

set(CMAKE_INSTALL_PREFIX /)
install(DIRECTORY brcm DESTINATION lib/firmware FILES_MATCHING PATTERN "*.hcd")
install(FILES DEVICES.md README.md LICENSE.broadcom_bcm20702 LICENSE.MIT.txt
	DESTINATION usr/share/doc/${CMAKE_PROJECT_NAME}-${CMAKE_PROJECT_VERSION})

set(CPACK_PACKAGE_VERSION ${CMAKE_PROJECT_VERSION})
set(CPACK_PACKAGE_NAME "broadcom-bt-firmware")
set(CPACK_PACKAGE_CONTACT "Azamat H. Hackimov <azamat.hackimov@gmail.com")
set(CPACK_PACKAGE_VENDOR "Azamat H. Hackimov")
set(CPACK_PACKAGE_DESCRIPTION "Firmware for Broadcom Bluetooth devices")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Firmware of Broadcom WIDCOMM® Bluetooth devices (including BCM20702, BCM20703, BCM43142 chipsets and other) for Linux kernel.")
set(CPACK_GENERATOR "DEB;RPM")
set(CPACK_PACKAGING_INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX})
set(CPACK_PACKAGE_FILE_NAME "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}")

# RPM specific options
set(CPACK_RPM_PACKAGE_LICENSE "WIDCOMM Bluetooth Software License")
set(CPACK_RPM_PACKAGE_ARCHITECTURE "noarch")

# DEB specific options
set(CPACK_DEBIAN_PACKAGE_SECTION "non-free/kernel")
set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "all")

include(CPack)

