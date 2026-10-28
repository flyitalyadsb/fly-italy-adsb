#!/bin/bash

# The receiver's UUID. Lightcone and the feeder pages know a receiver by it, so
# the feed and mlat-client must send the same one:
# - the feed (readsb, beast_reduce_plus_out) reads it with --uuid-file $UUID_FILE;
# - mlat-client (flyitalyadsb fork) reads /boot/flyitalyadsb-uuid first, then
#   $UUID_FILE, and sends it in its handshake.
UUID_FILE="/usr/local/share/flyitalyadsb/flyitalyadsb-uuid"
BOOT_UUID_FILE="/boot/flyitalyadsb-uuid"
UUID_RE='^\{?[A-F0-9a-f]{8}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{12}\}?$'

# Let's make sure the UUID tools are installed...
UUIDGEN=$(command -v uuidgen)
RV=$?

if [ $RV -ne 0 ]; then
    echo "Can't find uuidgen in path, trying to install uuidgen..."
    apt-get -y install uuid-runtime
    UUIDGEN=$(command -v uuidgen)
    RV=$?
    if [ $RV -ne 0 ]; then
        echo "Failed to install uuid-runtime package - need manual intervention!"
        sleep 60
        exit 10
    fi
fi

mkdir -p "$(dirname "$UUID_FILE")"

# A valid UUID in /boot is the one mlat-client already sends: the feed sends it too.
if [ -f "$BOOT_UUID_FILE" ]; then
    BOOT_UUID=$(head -n 1 "$BOOT_UUID_FILE")
    if [[ $BOOT_UUID =~ $UUID_RE ]] && [ "$(head -n 1 "$UUID_FILE" 2>/dev/null)" != "$BOOT_UUID" ]; then
        echo "Using the UUID in $BOOT_UUID_FILE ($BOOT_UUID), the one mlat-client sends."
        echo "Previous UUID in $UUID_FILE: $(head -n 1 "$UUID_FILE" 2>/dev/null || echo none)"
        echo "$BOOT_UUID" > "$UUID_FILE"
    fi
fi

# Check for a (valid) UUID...
if [ -f "$UUID_FILE" ]; then
    UUID=$(cat "$UUID_FILE")
    if ! [[ $UUID =~ $UUID_RE ]]; then
        # Data in UUID file is invalid.  Regenerate it!
        echo "WARNING: Data in UUID file was invalid.  Regenerating UUID."
        rm -f "$UUID_FILE"
        UUID=$($UUIDGEN)
        echo "New UUID: $UUID"
        echo "$UUID" > "$UUID_FILE"
    else
        echo "Using existing valid UUID ($UUID) from $UUID_FILE"
    fi
else
    # not found generate uuid and save it
    echo "WARNING: No UUID file found, generating new UUID..."
    UUID=$($UUIDGEN)
    echo "New UUID: $UUID"
    echo "$UUID" > "$UUID_FILE"
fi

# The feed and mlat-client run as the flyitalyadsb user: they must be able to read it.
chmod 644 "$UUID_FILE"

exit 0
