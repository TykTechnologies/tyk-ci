#!/bin/sh

include(header.m4)

if command -V systemctl >/dev/null 2>&1; then
    if [ ! -f /lib/systemd/system/xCOMPATIBILITY_NAME.service ]; then
        cp /opt/xCOMPATIBILITY_NAME/install/xCOMPATIBILITY_NAME.service /lib/systemd/system/xCOMPATIBILITY_NAME.service
    fi
fi
