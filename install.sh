#!/bin/bash
TMP=/tmp/flyitalyadsb-git
if ! command -v git; then
    apt-get update
    apt-get install -y git
fi
rm -rf "$TMP"
git clone https://github.com/flyitalyadsb/fly-italy-adsb.git "$TMP"
cd "$TMP" || exit 1;
BACKTITLETEXT="FlyItalyADSB"
if whiptail --backtitle "$BACKTITLETEXT" --title "$BACKTITLETEXT" --yes-button ENGLISH --no-button ITALIANO --yesno "Benvenuto su FlyItalyADSB. Welcome to FlyItalyADSB\n\nSeleziona la tua lingua. Select your language." 13 78;
then source $PWD/english/setup.sh
else source $PWD/italian/setup.sh
fi

