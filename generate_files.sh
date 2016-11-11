#!/bin/bash

echo "Make sure that you downloaded and unpacked into source directory latest drivers from Broadcom site."
echo "In source directory should be bcbtums.inf and *.hex files."
echo "Other stuff is not required."

echo ""
echo "Removing old hcd-files..."

rm -fr brcm/*.hcd

echo ""
echo "Generating new hcd-files..."

tools/bt-fw-converter.pl -f source/bcbtums.inf -d DEVICES.md -o brcm/

echo ""
echo "Done!"
