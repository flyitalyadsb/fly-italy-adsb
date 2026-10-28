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
    echo "Installazione annullata (probabilmente premendo ESC)."
    echo "Se non volevi, esegui di nuovo questo script."
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
    echo "Lo script deve essere eseguito tramite sudo o come utente root"
    echo -e "\033[37m"
    exit 1
fi

## CHECK FOR PACKAGES NEEDED BY THIS SCRIPT

echo "Verifico i pacchetti necessari per eseguire questo script.."

## ASSIGN VARIABLES

IPATH=/usr/local/share/flyitalyadsb
LOGDIRECTORY="$PWD/logs"

## WHIPTAIL DIALOGS

BACKTITLETEXT="Script di installazione del feed di FlyItalyADSB"

whiptail --backtitle "$BACKTITLETEXT" --title "$BACKTITLETEXT" --yes-button SI --no-button NO --yesno "Grazie per aver scelto di condividere i tuoi dati con FlyItalyADSB, una rete community globale, nata in Italia nel 2020.\n\nQuesto script manda a FlyItalyADSB i dati e la MLAT del tuo ricevitore. Serve un decoder che gira già su questo dispositivo (dump1090-fa, readsb, PiAware, FR24...). Parti da zero? Segui invece la guida per i feeder:\nhttps://flyitalyadsb.com/community/feeder/\n\nCosa ottieni: l'API con i limiti Pro, gratis, per uso non commerciale, e Lightcone: gli aerei passati vicino al tuo ricevitore che non ha ricevuto.\n\nVuoi continuare con l'installazione?" 20 78
if [[ $? != 0 ]]; then abort; fi

FLYITALYADSB_=$(whiptail --backtitle "$BACKTITLETEXT" --title "Nome utente" --nocancel --inputbox "\nPer favore inserisci un nome per il tuo ricevitore: lo identifica nella rete MLAT.\n\nUsa solo lettere e numeri.\nEsempio: \"Giorgio34\", \"Piacenza1\", etc." 12 78 3>&1 1>&2 2>&3)

if [[ $? != 0 ]]; then abort; fi

whiptail --backtitle "$BACKTITLETEXT" --title "$BACKTITLETEXT" \
    --msgbox "La MLAT ha bisogno della posizione esatta dell'antenna.\
    \n\nUn errore di 5 metri causa già gravi problemi.\
    \n\nPer trovare le coordinate puoi usare un sito come mapcoordinates.net" 12 78

if [[ $? != 0 ]]; then abort; fi

#((-90 <= RECEIVERLATITUDE <= 90))
LAT_OK=0
until [ $LAT_OK -eq 1 ]; do
    RECEIVERLATITUDE=$(whiptail --backtitle "$BACKTITLETEXT" --title "Latitudine dell'antenna ${RECEIVERLATITUDE:-}" --nocancel --inputbox "\nInserisci la latitudine in gradi dell'antenna con almeno 5 decimali.\n(Esempio: 45.36373)" 12 78 3>&1 1>&2 2>&3)
    if [[ $? != 0 ]]; then abort; fi
    LAT_OK=`awk -v LAT="$RECEIVERLATITUDE" 'BEGIN {printf (LAT<90 && LAT>-90 ? "1" : "0")}'`
done


#((-180<= RECEIVERLONGITUDE <= 180))
LON_OK=0
until [ $LON_OK -eq 1 ]; do
    RECEIVERLONGITUDE=$(whiptail --backtitle "$BACKTITLETEXT" --title "Longitudine dell'antenna ${RECEIVERLONGITUDE:-}" --nocancel --inputbox "\nInserisci la longitudine in gradi dell'antenna con almeno 5 decimali.\n(Esempio: 9.78342)" 12 78 3>&1 1>&2 2>&3)
    if [[ $? != 0 ]]; then abort; fi
    LON_OK=`awk -v LAT="$RECEIVERLONGITUDE" 'BEGIN {printf (LAT<180 && LAT>-180 ? "1" : "0")}'`
done

ALT=""
until [[ $ALT =~ ^(.*)ft$ ]] || [[ $ALT =~ ^(.*)m$ ]]; do
    ALT=$(whiptail --backtitle "$BACKTITLETEXT" --title "Altitudine dell'antenna sul livello del mare" \
        --nocancel --inputbox \
"\nInserisci l'altitudine con la sua unità:\n\n\
in piedi:                  255ft\n\
o in metri:                78m\n" \
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

whiptail --backtitle "$BACKTITLETEXT" --title "$BACKTITLETEXT" --yes-button SI --no-button NO --yesno "Ora sei pronto per condividere i tuoi dati con FlyItalyADSB.\nProseguendo dichiari di aver letto e accettato i termini (https://flyitalyadsb.com/termini/) e l'informativa privacy (https://flyitalyadsb.com/privacy/).\n\nVuoi continuare?" 12 78
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

    echo "Installando i prerequisiti" >> $LOGFILE
    echo "--------------------------------------" >> $LOGFILE
    echo "" >> $LOGFILE


    # Check that the prerequisite packages needed to build and install mlat-client are installed.

    # only install ntp if chrony and ntpsec aren't running
    if ! systemctl status chrony &>/dev/null && ! systemctl status ntpsec &>/dev/null; then
        required_packages="ntp "
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
        echo "Installando mlat-client in un virtual-env" >> $LOGFILE
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
        echo "Mlat-client è già stato installato, git hash:" >> $LOGFILE
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

    # SETUP FEEDER TO SEND DUMP1090 DATA TO FLYITALYADSB

    echo "" >> $LOGFILE
    echo " COMPILANDO E INSTALLANDO IL FEED" >> $LOGFILE
    echo "-------------------------------------------------" >> $LOGFILE
    echo "" >> $LOGFILE

    #save working dir to come back to it
    SCRIPT_DIR=$PWD

    READSB_REPO="https://github.com/flyitalyadsb/readsb.git"
    READSB_VERSION="$(git ls-remote $READSB_REPO 2>> $LOGFILE | grep HEAD | cut -f1)"
    if ! grep -e "$READSB_VERSION" -qs $IPATH/readsb_version; then
        echo "Compilando e installando il client del feed" >> $LOGFILE
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
        echo "Il client è già installato, git hash:" >> $LOGFILE 2>&1
        cat $IPATH/readsb_version >> $LOGFILE 2>&1
    fi

    # back to the working dir for install script
    cd $SCRIPT_DIR
    #end compile readsb

    echo "" >> $LOGFILE
    echo "" >> $LOGFILE

    cp $PWD/scripts/flyitalyadsb-feed.sh $IPATH >> $LOGFILE 2>&1
    cp $PWD/scripts/flyitalyadsb-feed.service /lib/systemd/system >> $LOGFILE 2>&1

    # Lightcone: il comando che chiede il codice del ricevitore, ora e dopo
    install -D -m 755 "$PWD/scripts/flyitalyadsb-lightcone" /usr/local/bin/flyitalyadsb-lightcone >> "$LOGFILE" 2>&1

    # Il vecchio pacchetto di statistiche (flyitalyadsb-stats) manda a un server
    # che non esiste più: lo sostituisce Lightcone. Qui lo fermo; uninstall.sh lo toglie.
    if [ -f /etc/systemd/system/flyitalyadsb-stats.service ]; then
        systemctl disable --now flyitalyadsb-stats.service >> "$LOGFILE" 2>&1
    fi

    tee /etc/default/flyitalyadsb > /dev/null 2>> $LOGFILE <<EOF
    INPUT="127.0.0.1:30005"
    REDUCE_INTERVAL="0.5"
    # nome MLAT di questo ricevitore
    UTENTE="${NOSPACENAME}"
    # lingua di flyitalyadsb-lightcone (en o it)
    FLYITALYADSB_LANG="it"
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
        echo "Scarico il repository di mlat-client" >> $LOGFILE 2>&1
        mkdir -p "$MLAT_GIT_DIR"
        chown flyitalyadsb "$MLAT_GIT_DIR"
        sudo -u flyitalyadsb git clone "$MLAT_REPO" "$MLAT_GIT_DIR"  >> $LOGFILE 2>&1

        echo "Eseguo lo script di aggiornamento" >> $LOGFILE 2>&1
        cd "$MLAT_GIT_DIR" || exit 1
        ./scripts/update.sh >> $LOGFILE 2>&1
    fi

    echo "Installo il timer systemd per scaricare in automatico gli aggiornamenti" >> $LOGFILE 2>&1
    printf "%s" "$UPDATER_SYSTEMD_SERVICE" > "$UPDATER_SYSTEMD_SERVICE_PATH"
    chmod 644 "$UPDATER_SYSTEMD_SERVICE_PATH"
    printf "%s" "$UPDATER_SYSTEMD_TIMER" > "$UPDATER_SYSTEMD_TIMER_PATH"
    chmod 644 "$UPDATER_SYSTEMD_TIMER_PATH"

    echo "Avvio updater" >> $LOGFILE 2>&1
    systemctl enable flyitalyadsb-mlat-updater.timer >> $LOGFILE 2>&1
    systemctl start flyitalyadsb-mlat-updater.timer >> $LOGFILE 2>&1

    echo "Riavvio mlat-client" >> $LOGFILE 2>&1
    systemctl restart flyitalyadsb-mlat >> $LOGFILE 2>&1

    echo "Updater installato correttamente" >> $LOGFILE 2>&1

} | whiptail --backtitle "$BACKTITLETEXT" --title "Impostando il feed di FlyItalyADSB"  --gauge "\nImpostando il feed di FlyItalyADSB.\nPotrebbe impiegarci qualche minuto..." 8 60 0

whiptail --backtitle "$BACKTITLETEXT" --title "$BACKTITLETEXT" --yes-button SI --no-button NO --yesno "Vuoi installare una mappa in cui sono visibili gli aerei che \nstai ricevendo in questo momento?\nSarà accessibile in locale a tuo_ip/flyitalyadsb" 9 70 0
INTERFACCIA=$?
if [ $INTERFACCIA = 0 ]; then
{
    set -e
    trap 'echo "------------"; echo "[ERROR] Error in line $LINENO when executing: $BASH_COMMAND"' ERR
    REPO="https://github.com/wiedehopf/tar1090"
    BRANCH="master"
    GIT="/usr/local/share/tar1090/git"
    getGIT "$REPO" "$BRANCH" "$GIT"
    bash "$GIT/install.sh" "/run/flyitalyadsb-feed" "flyitalyadsb" >> $LOGFILE 2>&1
}| whiptail --backtitle "$BACKTITLETEXT" --title "Impostando la mappa di FlyItalyADSB"  --gauge "\nImpostando la mappa di FlyItalyADSB.\nPotrebbe impiegarci qualche minuto..." 8 60 0
fi

# graphs1090: grafici locali di quello che riceve il ricevitore. Lo chiedo solo
# se non è già installato.
if [ ! -d /usr/share/graphs1090 ]; then
    whiptail --backtitle "$BACKTITLETEXT" --title "$BACKTITLETEXT" --yes-button SI --no-button NO --yesno "Vuoi installare graphs1090?\n\nGrafici locali di quello che riceve il tuo ricevitore (messaggi, distanza, aerei), su questo dispositivo a tuo_ip/graphs1090.\n\nLightcone aggiunge quello che un ricevitore da solo non può vedere: gli aerei passati vicino che non ha ricevuto." 13 70
    GRAPHS=$?
    if [ $GRAPHS = 0 ]; then
    {
        set -e
        trap 'echo "------------"; echo "[ERROR] Error in line $LINENO when executing: $BASH_COMMAND"' ERR
        REPO="https://github.com/wiedehopf/graphs1090"
        BRANCH="master"
        GIT="/tmp/graphs1090"
        getGIT "$REPO" "$BRANCH" "$GIT"
        echo 25
        cd "$GIT"
        bash install.sh >> "$LOGFILE" 2>&1
        echo 100
    } | whiptail --backtitle "$BACKTITLETEXT" --title "Impostando graphs1090"  --gauge "\nImpostando graphs1090.\nPotrebbe impiegarci qualche minuto..." 8 60 0
    fi
fi

# Il decoder manda dati? Senza, non ci sono né feed né MLAT.
HAS_DATA=1
if command -v nc &>/dev/null && ! nc -z 127.0.0.1 30005; then
    HAS_DATA=0
fi

# LIGHTCONE: chiedo il codice del ricevitore. Dopo il riavvio la MLAT può
# metterci un minuto a collegarsi: se "ancora nessun dato MLAT", richiedo una
# volta, 30 secondi dopo.
LIGHTCONE_TEXT="Lightcone: https://flyitalyadsb.com/community/lightcone/
Per collegare un dispositivo esegui: flyitalyadsb-lightcone"
if [ $HAS_DATA = 1 ] && [ -x /usr/local/bin/flyitalyadsb-lightcone ]; then
    LC_OUT=$(mktemp)
    {
        echo 5
        for TRY in 1 2; do
            /usr/local/bin/flyitalyadsb-lightcone --it > "$LC_OUT" 2>&1
            if [ $? -ne 2 ] || [ $TRY -eq 2 ]; then
                break
            fi
            for i in $(seq 1 30); do echo $((5 + i * 3)); sleep 1; done
        done
        echo 100
    } | whiptail --backtitle "$BACKTITLETEXT" --title "Lightcone" --gauge "\nChiedo a FlyItalyADSB il tuo codice per Lightcone.\nPuò servire fino a un minuto..." 8 60 0
    LIGHTCONE_TEXT=$(cat "$LC_OUT")
    rm -f "$LC_OUT"
fi
LIGHTCONE_TEXT=$(echo "$LIGHTCONE_TEXT" | sed -e '1s/^Lightcone: //' -e 's/^/  /')


## SETUP COMPLETE

ENDTEXT="Installazione completata: il tuo ricevitore ora manda i dati e la
MLAT a FlyItalyADSB.

Cosa ottieni mandandoci i dati:
- L'API con i limiti Pro, gratis, per uso non commerciale.
  Attivali da La mia API, dalla rete del ricevitore:
  https://flyitalyadsb.com/dati/api/account/
- Lightcone: gli aerei passati vicino a te che il tuo ricevitore non
  ha ricevuto, e come vai rispetto ai ricevitori vicini.
  Dalla rete del ricevitore la pagina riconosce il tuo ricevitore:
${LIGHTCONE_TEXT}

I miei dati arrivano? Apri questa pagina dalla rete del ricevitore:
https://flyitalyadsb.com/community/stato-feeder/

Problemi: https://flyitalyadsb.com/contatti/
oppure installazione@flyitalyadsb.com"

if [ $HAS_DATA = 0 ]; then
    ENDTEXT2="
---------------------
Nessun dato sulla porta 30005!
---------------------
Se non hai installato nessun decoder, la guida per i feeder
configura un ricevitore da zero:
https://flyitalyadsb.com/community/feeder/
Se il feed deve ricevere i dati da un'altra porta o IP, cambia INPUT
in /etc/default/flyitalyadsb e riavvia flyitalyadsb-feed e
flyitalyadsb-mlat.
--------------------
"
    if [ -f /etc/fr24feed.ini ] || [ -f /etc/rb24.ini ]; then
        ENDTEXT2+="
Sembra che usi FR24 o RB24: attiva l'uscita dei dati sulla
porta 30005. Per farlo:
- apri ip_del_tuo_raspberry:8754/settings
- in \"Process arguments\" aggiungi \" --net\"
- imposta NO in RAW DATA, SBS FEED e DECODED DATA
- premi \"Save\" e poi \"Restart\"
Se ancora non funziona, scrivici a installazione@flyitalyadsb.com
---------------------
"
    else
        ENDTEXT2+="
Se hai collegato una chiavetta SDR a questo dispositivo ma non hai
ancora installato il decoder, la guida per i feeder lo spiega:
https://flyitalyadsb.com/community/feeder/
---------------------
"
    fi
    ENDTEXT2+="
Quando i dati arrivano hai l'API con i limiti Pro, gratis, e
Lightcone. Allora esegui flyitalyadsb-lightcone per il tuo codice.
"
    whiptail --title "Script di installazione del feed di FlyItalyADSB" --scrolltext --msgbox "$ENDTEXT2" 27 73
    echo -e "$ENDTEXT2"
else
    # Display the thank you message box.
    whiptail --title "Script di installazione del feed di FlyItalyADSB" --scrolltext --msgbox "$ENDTEXT" 27 73
    echo -e "$ENDTEXT"
fi

cp $LOGFILE $IPATH/lastlog &>/dev/null
exit 0
