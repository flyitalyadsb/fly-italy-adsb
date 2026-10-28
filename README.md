# FlyItalyADSB feed script

Sends the data and MLAT of a receiver that **already runs a decoder** (dump1090-fa, readsb,
PiAware, the FR24 image…) to [FlyItalyADSB](https://flyitalyadsb.com/en/?utm_source=github&utm_campaign=fly-italy-adsb),
a community network born in Italy, with about 3,200 receivers all over the world.

Starting from scratch? Set up the receiver with ultrafeeder: see the
[feeder guide](https://flyitalyadsb.com/en/community/feeder/?utm_source=github&utm_campaign=fly-italy-adsb).

## What feeding gets you

- **The API with Pro limits, free:** 300 requests a minute, 10 million a month, the whole
  world, on your Free keys, for non-commercial use.
  [Turn it on in My API](https://flyitalyadsb.com/en/data/api/account/?utm_source=github&utm_campaign=fly-italy-adsb)
  from your receiver's network.
- **What flew past you:** [Lightcone](https://flyitalyadsb.com/en/community/lightcone/?utm_source=github&utm_campaign=fly-italy-adsb)
  shows the aircraft that passed near you and your receiver did not receive, and how you
  compare with the receivers within 40 km. graphs1090 and tar1090 only show what you received.

## Who it is for

- A Raspberry Pi or Linux machine (apt or yum) with a decoder serving Beast on port 30005.
  The script reads from `127.0.0.1:30005` by default.
- Using FR24's feeder? Enable the Beast output on port 30005 first: the script explains how
  at the end if it finds no data there.

## Install

```
wget -O /tmp/flyitalyadsbfeed.sh https://raw.githubusercontent.com/flyitalyadsb/fly-italy-adsb/master/install.sh
sudo bash /tmp/flyitalyadsbfeed.sh
```

The script asks for a name for your receiver, the antenna position (at least 5 decimal
places: MLAT needs it within a few metres) and its altitude.

## Check that your data arrives

Open the [feeder status page](https://flyitalyadsb.com/en/community/feeder-status/?utm_source=github&utm_campaign=fly-italy-adsb)
from a device on the receiver's network.

### Show the configuration

```
cat /etc/default/flyitalyadsb
```

If the decoder is on another port or machine, change `INPUT` there and restart both services.

### Restart

```
sudo systemctl restart flyitalyadsb-feed
sudo systemctl restart flyitalyadsb-mlat
```

### Status and logs

```
sudo systemctl status flyitalyadsb-feed
sudo systemctl status flyitalyadsb-mlat
sudo journalctl -u flyitalyadsb-feed --no-pager
sudo journalctl -u flyitalyadsb-mlat --no-pager
```

If something does not work, [contact us](https://flyitalyadsb.com/en/contact/?utm_source=github&utm_campaign=fly-italy-adsb)
or write to installazione@flyitalyadsb.com with the last twenty lines of both logs.

### Remove

```
sudo bash /usr/local/share/flyitalyadsb/uninstall.sh
```

<details>
<summary>In italiano</summary>

Manda i dati e la MLAT di un ricevitore che **ha già un decoder** (dump1090-fa, readsb,
PiAware, l'immagine di FR24…) a FlyItalyADSB, una rete community nata in Italia, con circa
3.200 ricevitori in tutto il mondo. Parti da zero? Configura il ricevitore con ultrafeeder:
la [guida per i feeder](https://flyitalyadsb.com/community/feeder/?utm_source=github&utm_campaign=fly-italy-adsb).

**Cosa ottieni mandandoci i dati:**

- **l'API con i limiti Pro, gratis:** 300 richieste al minuto, 10 milioni al mese, tutto il
  mondo, sulle tue chiavi Free, per uso non commerciale.
  [Attivali da La mia API](https://flyitalyadsb.com/dati/api/account/?utm_source=github&utm_campaign=fly-italy-adsb)
  dalla rete del ricevitore;
- **cosa ti è passato accanto:** [Lightcone](https://flyitalyadsb.com/community/lightcone/?utm_source=github&utm_campaign=fly-italy-adsb)
  mostra gli aerei passati vicino a te che il tuo ricevitore non ha ricevuto e come vai
  rispetto ai ricevitori entro 40 km. graphs1090 e tar1090 mostrano solo cosa hai ricevuto.

Installazione: gli stessi due comandi qui sopra. Per controllare che i dati arrivino, apri
la pagina [I miei dati arrivano?](https://flyitalyadsb.com/community/stato-feeder/?utm_source=github&utm_campaign=fly-italy-adsb)
da un dispositivo sulla rete del ricevitore. Problemi:
[contattaci](https://flyitalyadsb.com/contatti/?utm_source=github&utm_campaign=fly-italy-adsb)
o scrivi a installazione@flyitalyadsb.com.

</details>
