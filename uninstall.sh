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

# Everything in $IPATH except the receiver's UUID: after a reinstall it stays
# the same receiver for Lightcone and the feeder pages.
find "$IPATH" -mindepth 1 -maxdepth 1 ! -name flyitalyadsb-uuid -exec rm -rf {} +

set +x

echo -----
echo "flyitalyadsb feed scripts have been uninstalled!"
echo "The receiver's UUID is kept in $IPATH/flyitalyadsb-uuid:"
echo "if you install again, it stays the same receiver for Lightcone and the feeder pages."
echo "L'UUID del ricevitore resta in $IPATH/flyitalyadsb-uuid:"
echo "se reinstalli, resta lo stesso ricevitore per Lightcone e le pagine dei feeder."
