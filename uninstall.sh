#!/bin/bash
set -x

IPATH=/usr/local/share/flyitalyadsb

systemctl disable --now flyitalyadsb-mlat
systemctl disable --now flyitalyadsb-feed
systemctl disable --now flyitalyadsb-mlat-updater.timer

rm -f /lib/systemd/system/flyitalyadsb-mlat.service
rm -f /lib/systemd/system/flyitalyadsb-feed.service
rm -f /lib/systemd/system/flyitalyadsb-mlat-updater.service
rm -f /lib/systemd/system/flyitalyadsb-mlat-updater.timer

# Lightcone helper
rm -f /usr/local/bin/flyitalyadsb-lightcone

# The old statistics package (flyitalyadsb-stats), if this receiver still has it
if [ -f /usr/local/share/flyitalyadsb-stats/uninstall.sh ]; then
    bash /usr/local/share/flyitalyadsb-stats/uninstall.sh
fi

systemctl daemon-reload

rm -rf "$IPATH"

set +x

echo -----
echo "flyitalyadsb feed scripts have been uninstalled!"
