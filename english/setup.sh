#!/bin/bash -eu

#####################################################################################
#                        FLY ITALY ADSB SETUP SCRIPT FORKED                         #
#####################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                                                                                   #
# Copyright (c) 2023 Fly Italy Adsb                                                 #
#                                                                                   #
# Permission is hereby granted, free of charge, to any person obtaining a copy      #
# of this software and associated documentation files (the "Software"), to deal     #
# in the Software without restriction, including without limitation the rights      #
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell         #
# copies of the Software, and to permit persons to whom the Software is             #
# furnished to do so, subject to the following conditions:                          #
#                                                                                   #
# The above copyright notice and this permission notice shall be included in all    #
# copies or substantial portions of the Software.                                   #
#                                                                                   #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR        #
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,          #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE       #
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER            #
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,     #
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE     #
# SOFTWARE.                                                                         #
#                                                                                   #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#####################################################################################
#                        ADS-B EXCHANGE SETUP SCRIPT FORKED                         #
#####################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                                                                                   #
# Copyright (c) 2018 ADSBx                                    #
#                                                                                   #
# Permission is hereby granted, free of charge, to any person obtaining a copy      #
# of this software and associated documentation files (the "Software"), to deal     #
# in the Software without restriction, including without limitation the rights      #
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell         #
# copies of the Software, and to permit persons to whom the Software is             #
# furnished to do so, subject to the following conditions:                          #
#                                                                                   #
# The above copyright notice and this permission notice shall be included in all    #
# copies or substantial portions of the Software.                                   #
#                                                                                   #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR        #
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,          #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE       #
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER            #
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,     #
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE     #
# SOFTWARE.                                                                         #
#                                                                                   #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function abort() {
    echo ------------
    echo "Installation canceled (probably by pressing ESC)!"
    echo "If these were not your intentions please execute again this script"
    echo ------------
    exit 1
}

function getGIT() {
    # getGIT $REPO $BRANCH $TARGET-DIR
    if [[ -z "$1" ]] || [[ -z "$2" ]] || [[ -z "$3" ]]; then
        echo "getGIT wrong usage, check your script or tell the author!" 1>&2
        return 1
    fi
    if ! cd "$3" &>/dev/null || ! git fetch origin "$2" >> $LOGFILE 2>&1|| ! git reset --hard FETCH_HEAD>> $LOGFILE 2>&1; then
        if ! rm -rf "$3" || ! git clone --depth 2 --single-branch --branch "$2" "$1" "$3" >> $LOGFILE 2>&1; then
            return 1
        fi
    fi
    return 0
}

## CHECK IF SCRIPT WAS RAN USING SUDO

if [ "$(id -u)" != "0" ]; then
    echo -e "\033[33m"
    echo "The script has to be executed through sudo or through the root user"
    echo -e "\033[37m"
    exit 1
fi

## CHECK FOR PACKAGES NEEDED BY THIS SCRIPT

echo "Checking the packages needed to execute this script.."

## ASSIGN VARIABLES

IPATH=/usr/local/share/flyitalyadsb
LOGDIRECTORY="$PWD/logs"

## WHIPTAIL DIALOGS

BACKTITLETEXT="FlyItalyADSB feed installation script"

whiptail --backtitle "$BACKTITLETEXT" --title "$BACKTITLETEXT" --yes-button YES --no-button NO --yesno "Thank you for choosing to share your data with FlyItalyADSB.\n\nFlyItalyADSB is a community network born in Italy, with receivers all over the world. This script sets up your receiver to send its data and MLAT to FlyItalyADSB.\n\nDo you want to continue with the installation?" 13 78
if [[ $? != 0 ]]; then abort; fi

FLYITALYADSB_=$(whiptail --backtitle "$BACKTITLETEXT" --title "User name" --nocancel --inputbox "\nPlease insert a name for your receiver: it identifies it in the MLAT network.\n\nUse only letters or numbers.\nExample: \"Station1\", \"Hilltop42\", etc." 12 78 3>&1 1>&2 2>&3)

if [[ $? != 0 ]]; then abort; fi

whiptail --backtitle "$BACKTITLETEXT" --title "$BACKTITLETEXT" \
    --msgbox "For the correct functioning of the multilateration insert precisely the position of the antenna\
    \n\nAn error of 5 meters will cause serious problems!\
    \n\nTo get the right coordinates you can visit a site like mapcoordinates.net" 12 78

if [[ $? != 0 ]]; then abort; fi

#((-90 <= RECEIVERLATITUDE <= 90))
LAT_OK=0
until [ $LAT_OK -eq 1 ]; do
    RECEIVERLATITUDE=$(whiptail --backtitle "$BACKTITLETEXT" --title "Antenna's latitude ${RECEIVERLATITUDE:-}" --nocancel --inputbox "\nInsert the antenna's latitude in degree with at least 5 decimal places.\n(Example: 45.36373)" 12 78 3>&1 1>&2 2>&3)
    if [[ $? != 0 ]]; then abort; fi
    LAT_OK=`awk -v LAT="$RECEIVERLATITUDE" 'BEGIN {printf (LAT<90 && LAT>-90 ? "1" : "0")}'`
done


#((-180<= RECEIVERLONGITUDE <= 180))
LON_OK=0
until [ $LON_OK -eq 1 ]; do
    RECEIVERLONGITUDE=$(whiptail --backtitle "$BACKTITLETEXT" --title "Antenna's longitude ${RECEIVERLONGITUDE:-}" --nocancel --inputbox "\nInsert the antenna's longitude in degree with at least 5 decimal places.\n(Example: 9.78342)" 12 78 3>&1 1>&2 2>&3)
    if [[ $? != 0 ]]; then abort; fi
    LON_OK=`awk -v LAT="$RECEIVERLONGITUDE" 'BEGIN {printf (LAT<180 && LAT>-180 ? "1" : "0")}'`
done

ALT=""
until [[ $ALT =~ ^(.*)ft$ ]] || [[ $ALT =~ ^(.*)m$ ]]; do
    ALT=$(whiptail --backtitle "$BACKTITLETEXT" --title "Antenna's altitude on the sea level:" \
        --nocancel --inputbox \
"\nInsert the altitude including the unit:\n\n\
This way using feets:                   255ft\n\
or this way using meters:               78m\n" \
        12 78 3>&1 1>&2 2>&3)
    if [[ $? != 0 ]]; then abort; fi
done

if [[ $ALT =~ ^-(.*)ft$ ]]; then
        NUM=${BASH_REMATCH[1]}
        NEW_ALT=`echo "$NUM" "3.28" | awk '{printf "-%0.2f", $1 / $2 }'`
        ALT=$NEW_ALT
fi
if [[ $ALT =~ ^-(.*)m$ ]]; then
        NEW_ALT="-${BASH_REMATCH[1]}"
        ALT=$NEW_ALT
fi

RECEIVERALTITUDE="$ALT"



whiptail --backtitle "$BACKTITLETEXT" --title "$BACKTITLETEXT" --yes-button YES --no-button NO --yesno "Now you're ready to share your data with FlyItalyADSB.\nBy proceeding you declare that you have read and accepted our terms (https://flyitalyadsb.com/en/terms/) and privacy policy (https://flyitalyadsb.com/en/privacy/).\n\nDo you want to proceed?" 12 78
CONTINUESETUP=$?
if [ $CONTINUESETUP = 1 ]; then
    exit 0
fi


# Make a log directory if it does not already exist.
if [ ! -d "$LOGDIRECTORY" ]; then
    mkdir $LOGDIRECTORY
fi
LOGFILE="$LOGDIRECTORY/image_setup-$(date +%F_%R)"
touch $LOGFILE
mkdir -p $IPATH >> $LOGFILE  2>&1
cp uninstall.sh $IPATH >> $LOGFILE  2>&1


## BEGIN SETUP
{
    if ! id -u flyitalyadsb &>/dev/null
    then
        adduser --system --home $IPATH --no-create-home --quiet flyitalyadsb >> $LOGFILE  2>&1
    fi

    echo 4
    sleep 0.25

    # BUILD AND CONFIGURE THE MLAT-CLIENT PACKAGE

    echo "Installing the prerequisites" >> $LOGFILE
    echo "--------------------------------------" >> $LOGFILE
    echo "" >> $LOGFILE


    # Check that the prerequisite packages needed to build and install mlat-client are installed.

    # only install ntp if chrony and ntpsec aren't running
    if ! systemctl status chrony &>/dev/null && ! systemctl status ntpsec &>/dev/null; then
        _packages="ntp "
    fi

    progress=4

    APT_UPDATED="false"

    if command -v apt &>/dev/null; then
        required_packages+="git curl build-essential debhelper pkg-config libzstd-dev librtlsdr0 librtlsdr-dev  libzstd1 libusb-1.0-0-dev  librtlsdr-dev  python3-dev socat python3-venv libncurses-dev netcat-openbsd uuid-runtime zlib1g-dev zlib1g"
        for package in $required_packages; do
            if [ $(dpkg-query -W -f='${STATUS}' $package 2>/dev/null | grep -c "ok installed") -eq 0 ]; then

                [[ "$APT_UPDATED" == "false" ]] && apt update >> $LOGFILE 2>&1 && APT_UPDATED="true"
                [[ "$APT_UPDATED" == "false" ]] && apt update >> $LOGFILE 2>&1 && APT_UPDATED="true"
                [[ "$APT_UPDATED" == "false" ]] && apt update >> $LOGFILE 2>&1 && APT_UPDATED="true"

                echo Installing $package >> $LOGFILE  2>&1
                if ! apt install --no-install-recommends --no-install-suggests -y $package >> $LOGFILE  2>&1; then
                    # retry
                    apt clean >> $LOGFILE 2>&1
                    apt --fix-broken install -y >> $LOGFILE 2>&1
                    apt install --no-install-recommends --no-install-suggests -y $package >> $LOGFILE 2>&1
                fi
            fi
            progress=$((progress+2))
            echo $progress
        done
    elif command -v yum &>/dev/null; then
        required_packages+="git curl socat python3-virtualenv python3-devel gcc make ncurses-devel nc uuid zlib-devel zlib"
        yum install -y $required_packages >> $LOGFILE  2>&1
    fi

    hash -r

    bash create-uuid.sh >> $LOGFILE  2>&1

    echo "" >> $LOGFILE
    echo " BUILD AND INSTALL MLAT-CLIENT" >> $LOGFILE
    echo "-----------------------------------" >> $LOGFILE
    echo "" >> $LOGFILE

    CURRENT_DIR=$PWD

    MLAT_REPO="https://github.com/flyitalyadsb/mlat-client.git" 
    MLAT_VERSION="$(git ls-remote $MLAT_REPO 2>> $LOGFILE | grep HEAD | cut -f1)"
    if ! grep -e "$MLAT_VERSION" -qs $IPATH/mlat_version; then
        echo "Installing mlat-client in a virtual-env" >> $LOGFILE
        # Check if the mlat-client git repository already exists.
        VENV=$IPATH/venv
        mkdir -p $IPATH >> $LOGFILE 2>&1

        MLAT_DIR=/tmp/mlat-git
        # Download a copy of the mlat-client repository since the repository does not exist locally.
        rm -rf $MLAT_DIR
        git clone --depth 1 --single-branch $MLAT_REPO $MLAT_DIR >> $LOGFILE 2>&1
        cd $MLAT_DIR >> $LOGFILE 2>&1

        echo 34
        sleep 0.25


        rm "$VENV" -rf
        /usr/bin/python3 -m venv $VENV >> $LOGFILE 2>&1 && echo 36 \
            && source $VENV/bin/activate >> $LOGFILE 2>&1 && echo 38 \
            && python3 setup.py build >> $LOGFILE 2>&1 && echo 40 \
            && python3 setup.py install >> $LOGFILE 2>&1 \
            && git rev-parse HEAD > $IPATH/mlat_version 2>> $LOGFILE

    else
        echo "Mlat-client has already been installed, git hash:" >> $LOGFILE
        cat $IPATH/mlat_version >> $LOGFILE
    fi

    echo 44

    cd $CURRENT_DIR

    sleep 0.25
    echo 54

    NOSPACENAME="$(echo -n -e "${FLYITALYADSB_}" | tr -c '[a-zA-Z0-9]_\- ' '_')"

    echo 64
    sleep 0.25

    # copy flyitalyadsb-mlat service file
    cp $PWD/scripts/flyitalyadsb-mlat.sh $IPATH >> $LOGFILE 2>&1
    cp $PWD/scripts/flyitalyadsb-mlat.service /lib/systemd/system >> $LOGFILE 2>&1

    # Enable flyitalyadsb-mlat service
    systemctl enable flyitalyadsb-mlat >> $LOGFILE 2>&1

    echo 70
    sleep 0.25

    # SETUP FEEDER TO SEND DUMP1090 DATA TO FLY ITALY ADSB

    echo "" >> $LOGFILE
    echo " FILLING OUT AND INSTALLING THE FEED" >> $LOGFILE
    echo "-------------------------------------------------" >> $LOGFILE
    echo "" >> $LOGFILE

    #save working dir to come back to it
    SCRIPT_DIR=$PWD

    READSB_REPO="https://github.com/flyitalyadsb/readsb.git"
    READSB_VERSION="$(git ls-remote $READSB_REPO 2>> $LOGFILE | grep HEAD | cut -f1)"
    if ! grep -e "$READSB_VERSION" -qs $IPATH/readsb_version; then
        echo "Filling out and installing the feed's client" >> $LOGFILE
        echo "" >> $LOGFILE

        #compile readsb
        echo 72

        rm -rf /tmp/readsb &>/dev/null || true
        git clone --single-branch --depth 1 $READSB_REPO /tmp/readsb  >> $LOGFILE 2>&1
        cd /tmp/readsb
        echo 74
        if make -j3 AIRCRAFT_HASH_BITS=12 >> $LOGFILE 2>&1
        then
            git rev-parse HEAD > $IPATH/readsb_version 2>> $LOGFILE
        fi

        rm -f $IPATH/feed
        cp readsb $IPATH/feed >> $LOGFILE 2>&1

        cd /tmp
        rm -rf /tmp/readsb &>/dev/null || true
        echo "" >> $LOGFILE
        echo "" >> $LOGFILE
    else
        echo "The client has already been installed, git hash:" >> $LOGFILE 2>&1
        cat $IPATH/readsb_version >> $LOGFILE 2>&1
    fi

    # back to the working dir for install script
    cd $SCRIPT_DIR
    #end compile readsb

    echo "" >> $LOGFILE
    echo "" >> $LOGFILE

    cp $PWD/scripts/flyitalyadsb-feed.sh $IPATH >> $LOGFILE 2>&1
    cp $PWD/scripts/flyitalyadsb-feed.service /lib/systemd/system >> $LOGFILE 2>&1

    tee /etc/default/flyitalyadsb > /dev/null 2>> $LOGFILE <<EOF
    INPUT="127.0.0.1:30005"
    REDUCE_INTERVAL="0.5"
    # user name for controlling the status of the MLAT-Multilateration  (flyitalyadsb.com/status-mlat)
    UTENTE="${NOSPACENAME}"
    LATITUDINE="$RECEIVERLATITUDE"
    LONGITUDINE="$RECEIVERLONGITUDE"
    ALTITUDINE="$RECEIVERALTITUDE"
    RISULTATI="--results beast,connect,localhost:30104"
    RISULTATI2="--results basestation,listen,31003"
    RISULTATI3="--results beast,listen,30157"
    RISULTATI4="--results beast,connect,localhost:30600"
    
    INPUT_TYPE="dump1090"
    MLATSERVER="dati.flyitalyadsb.com:30100"
    TARGET="--net-connector dati.flyitalyadsb.com,4905,beast_reduce_plus_out,dati.flyitalyadsb.com,30102"
    NET_OPTIONS="--net-heartbeat 60 --net-ro-size 1280 --net-ro-interval 0.2 --net-ro-port 0 --net-sbs-port 0 --net-bi-port 30100 --net-bo-port 0 --net-ri-port 0"
EOF

    echo 82
    sleep 0.25

    # Enable flyitalyadsb-feed service
    systemctl enable flyitalyadsb-feed  >> $LOGFILE 2>&1

    echo 88
    sleep 0.25

    echo 94
    sleep 0.25

    # Start or restart flyitalyadsb-feed service
    systemctl restart flyitalyadsb-feed  >> $LOGFILE 2>&1

    echo 96

    # Start or restart flyitalyadsb-mlat service
    systemctl restart flyitalyadsb-mlat >> $LOGFILE 2>&1

    echo 100
    sleep 0.25

    MLAT_GIT_DIR="/usr/local/share/flyitalyadsb/mlat-client-git"

    UPDATER_SYSTEMD_SERVICE_PATH="/lib/systemd/system/flyitalyadsb-mlat-updater.service"
    read -r -d '' UPDATER_SYSTEMD_SERVICE <<-'EOF'
    [Unit]
    Description=Keep mlat-client up to date
    After=network.target
    [Service]
    Type=simple
    User=root
    WorkingDirectory=/usr/local/share/flyitalyadsb/mlat-client-git
    ExecStart=/usr/local/share/flyitalyadsb/mlat-client-git/scripts/update.sh
    [Install]
    WantedBy=timers.target
EOF

    ###

    UPDATER_SYSTEMD_TIMER_PATH="/lib/systemd/system/flyitalyadsb-mlat-updater.timer"
    read -r -d '' UPDATER_SYSTEMD_TIMER <<-'EOF'
    [Unit]
    Description=Keep mlat-client up to date
    [Timer]
    OnCalendar=daily
    Persistent=true
    [Install]
    WantedBy=timers.target
EOF


    if [ ! -d "$MLAT_GIT_DIR/.git" ]; then
        echo "Downloading mlat-client's repository" >> $LOGFILE 2>&1
        mkdir -p "$MLAT_GIT_DIR"
        chown flyitalyadsb "$MLAT_GIT_DIR"
        sudo -u flyitalyadsb git clone "$MLAT_REPO" "$MLAT_GIT_DIR"  >> $LOGFILE 2>&1

        echo "Executing the script update" >> $LOGFILE 2>&1
        cd "$MLAT_GIT_DIR" || exit 1
        ./scripts/update.sh >> $LOGFILE 2>&1
    fi

    echo "Installing the systemd timer to automatically download the updates" >> $LOGFILE 2>&1
    printf "%s" "$UPDATER_SYSTEMD_SERVICE" > "$UPDATER_SYSTEMD_SERVICE_PATH"
    chmod 644 "$UPDATER_SYSTEMD_SERVICE_PATH"
    printf "%s" "$UPDATER_SYSTEMD_TIMER" > "$UPDATER_SYSTEMD_TIMER_PATH"
    chmod 644 "$UPDATER_SYSTEMD_TIMER_PATH"

    echo "Starting updater" >> $LOGFILE 2>&1
    systemctl enable flyitalyadsb-mlat-updater.timer >> $LOGFILE 2>&1
    systemctl start flyitalyadsb-mlat-updater.timer >> $LOGFILE 2>&1

    echo "Relaunching mlat-client" >> $LOGFILE 2>&1
    systemctl restart flyitalyadsb-mlat >> $LOGFILE 2>&1

    echo "Updater correctly installed" >> $LOGFILE 2>&1

} | whiptail --backtitle "$BACKTITLETEXT" --title "Setting up the FlyItalyADSB feed"  --gauge "\nSetting up the FlyItalyADSB feed.\nIt could take a few minutes..." 8 60 0

whiptail --backtitle "$BACKTITLETEXT" --title "$BACKTITLETEXT" --yes-button YES --no-button NO --yesno "Do you want to install a map with all the planes that \nyou are receiving at this moment?\nIt will be accessible at your_ip/flyitalyadsb" 9 70 0 
INTERFACCIA=$?
if [ $INTERFACCIA = 0 ]; then
{   
    set -e
    trap 'echo "------------"; echo "[ERROR] Error in line $LINENO when executing: $BASH_COMMAND"' ERR


    REPO="https://github.com/wiedehopf/tar1090"
    BRANCH="master"
    GIT="/usr/local/share/tar1090/git"
    getGIT "$REPO" "$BRANCH" "$GIT" 
    bash "$GIT/install.sh" "/run/flyitalyadsb-feed" "flyitalyadsb"
}| whiptail --backtitle "$BACKTITLETEXT" --title "Setting up the FlyItalyADSB map"  --gauge "\nSetting up the FlyItalyADSB map.\nIt could take a few minutes..." 8 60 0
fi

whiptail --backtitle "$BACKTITLETEXT" --title "$BACKTITLETEXT" --yes-button YES --no-button NO --yesno "If you want subscribe to ours newsletter (Not more than a mail a month)." 10 70
MAIL=$?
if [ $MAIL = 0 ]; then
    set -e
    trap 'echo "------------"; echo "[ERROR] Error in line $LINENO when executing: $BASH_COMMAND"' ERR
    email=$(whiptail --backtitle "$BACKTITLETEXT" --title "Email"  --inputbox "\nInsert your email" 8 60 3>&1 1>&2 2>&3)
    curl -d "mail=$email" https://flyitalyadsb.com/newsletter.php  >> $LOGFILE 2>&1
fi


## SETUP COMPLETE

ENDTEXT="
Installation complete: your receiver now sends its data to FlyItalyADSB.
Check that your data arrives, from a device on the receiver's network:
---------------------
https://flyitalyadsb.com/en/community/feeder-status/
---------------------
What feeding gets you:
- the API with Pro limits, free, for non-commercial use.
  Turn it on in My API, from the receiver's network:
  https://flyitalyadsb.com/en/data/api/account/
- Lightcone: the aircraft that passed near you and you did not
  receive, and how you compare with the receivers near you:
  https://flyitalyadsb.com/en/community/lightcone/
---------------------
Problems or advice: https://flyitalyadsb.com/en/contact/
or installazione@flyitalyadsb.com
"


if ! nc -z 127.0.0.1 30005 && command -v nc &>/dev/null; then
    ENDTEXT2="
---------------------
No available data on the 30005 port! 
---------------------
If you haven't installed any decoder, the feeder guide sets up
a receiver from scratch: https://flyitalyadsb.com/en/community/feeder/
If the feed gets its data from another port or IP, change INPUT
in /etc/default/flyitalyadsb and restart flyitalyadsb-feed and
flyitalyadsb-mlat.
--------------------
"
    if [ -f /etc/fr24feed.ini ] || [ -f /etc/rb24.ini ]; then
        ENDTEXT2+="
It seems like you're using FR24 o BR24
This means that you have to enable the data trasmission on the 30005 port! To do so follow these instrucions: 
- go to this page: raspberry_ip:8754/settings.
- in \"process arguments\" add \" --net\" 
- set NO in RAW DATA, SBS FEED and DECODED DATA.
--Press \"Save\" and then \"restart\" 
If it still does not work, write to installazione@flyitalyadsb.com
---------------------
"
    else
        ENDTEXT2+="
If you have connected a SDR to this device but you still 
haven't installed the decoder, the feeder guide explains it:
https://flyitalyadsb.com/en/community/feeder/
---------------------
"
    fi
    whiptail --title "FlyItalyADSB feed installation script" --msgbox "$ENDTEXT2" 27 73
    echo -e "$ENDTEXT2"
else
    # Display the thank you message box.
    whiptail --title "FlyItalyADSB feed installation script" --msgbox "$ENDTEXT" 27 73 
    echo -e "$ENDTEXT"
fi

cp $LOGFILE $IPATH/lastlog &>/dev/null
exit 0
