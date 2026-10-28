# FlyItalyADSB feed script

[FlyItalyADSB](https://flyitalyadsb.com/en/?utm_source=github&utm_campaign=fly-italy-adsb) is a
global community network, born in Italy in 2020, with about 3,200 receivers.

This script sends the data and MLAT of a receiver that **already runs a decoder**
(dump1090-fa, readsb, PiAware, the FR24 image…) to FlyItalyADSB, and gives you the code that
links your receiver to Lightcone.

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
  Lightcone needs MLAT.

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

The script asks for a name for your receiver (its MLAT name), the antenna position (at least
5 decimal places: MLAT needs it within a few metres) and its altitude. Then it offers two
local tools, both optional: a tar1090 map of what you receive (`your_ip/flyitalyadsb`) and,
if it is not installed yet, graphs1090 (`your_ip/graphs1090`).

At the end it asks for your Lightcone code and shows what feeding gets you.

## Lightcone

Open [Lightcone](https://flyitalyadsb.com/en/community/lightcone/?utm_source=github&utm_campaign=fly-italy-adsb)
from the receiver's network: the page recognises your receiver. To link a device to it for
90 days, also from other networks, and to see terrain, readings and records too, enter the
receiver code. For a new code, run this on the receiver:

```
flyitalyadsb-lightcone
```

- The code lasts 10 minutes and works once.
- It only works from the network the receiver feeds from, once MLAT is connected. Right after
  the install this can take a few minutes: if there is no code yet, try again later.
- Several receivers behind the same address: `flyitalyadsb-lightcone --name <MLAT name>`.

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

## What it installs

- `flyitalyadsb-feed`: our readsb fork, sending the decoder's data to
  `dati.flyitalyadsb.com`.
- `flyitalyadsb-mlat`: our mlat-client fork in its own Python venv, with a daily update timer
  (`flyitalyadsb-mlat-updater.timer`). On Python 3.12 and later the venv also gets
  `setuptools` and `pyasyncore`, which newer Pythons no longer include.
- The receiver's UUID in `/usr/local/share/flyitalyadsb/flyitalyadsb-uuid`: the feed and
  mlat-client both send it, and Lightcone and the feeder pages know your receiver by it.
- `flyitalyadsb-lightcone` in `/usr/local/bin`, and the configuration in
  `/etc/default/flyitalyadsb`.

### Remove

```
sudo bash /usr/local/share/flyitalyadsb/uninstall.sh
```

It keeps the receiver's UUID (`/usr/local/share/flyitalyadsb/flyitalyadsb-uuid`): if you
install again, it stays the same receiver for Lightcone and the feeder pages.

It also removes the old statistics package (`flyitalyadsb-stats`) if the receiver still has
it: Lightcone replaces it. The tar1090 map and graphs1090 have their own uninstall scripts.

<details>
<summary>In italiano</summary>

FlyItalyADSB è una rete community globale, nata in Italia nel 2020, con circa 3.200
ricevitori.

Questo script manda a FlyItalyADSB i dati e la MLAT di un ricevitore che **ha già un
decoder** (dump1090-fa, readsb, PiAware, l'immagine di FR24…) e ti dà il codice che collega il
ricevitore a Lightcone. Parti da zero? Configura il ricevitore con ultrafeeder: la
[guida per i feeder](https://flyitalyadsb.com/community/feeder/?utm_source=github&utm_campaign=fly-italy-adsb).

**Cosa ottieni mandandoci i dati:**

- **l'API con i limiti Pro, gratis:** 300 richieste al minuto, 10 milioni al mese, tutto il
  mondo, sulle tue chiavi Free, per uso non commerciale.
  [Attivali da La mia API](https://flyitalyadsb.com/dati/api/account/?utm_source=github&utm_campaign=fly-italy-adsb)
  dalla rete del ricevitore;
- **cosa ti è passato accanto:** [Lightcone](https://flyitalyadsb.com/community/lightcone/?utm_source=github&utm_campaign=fly-italy-adsb)
  mostra gli aerei passati vicino a te che il tuo ricevitore non ha ricevuto e come vai
  rispetto ai ricevitori entro 40 km. graphs1090 e tar1090 mostrano solo cosa hai ricevuto.
  Lightcone ha bisogno della MLAT.

**Installazione:** gli stessi due comandi qui sopra. Lo script chiede il nome del ricevitore
(il nome MLAT), la posizione dell'antenna e la sua altitudine, poi offre due strumenti locali,
entrambi facoltativi: la mappa tar1090 (`tuo_ip/flyitalyadsb`) e, se non c'è già, graphs1090
(`tuo_ip/graphs1090`). Alla fine chiede il codice per Lightcone.

**Lightcone:** aperta dalla rete del ricevitore, la pagina riconosce il tuo ricevitore. Per
collegarci un dispositivo per 90 giorni, anche da altre reti, e vedere anche terreno, letture
e record, inserisci il codice del ricevitore. Per un nuovo codice esegui sul ricevitore
`flyitalyadsb-lightcone`: vale 10 minuti e una volta sola, e funziona solo dalla rete da cui il
ricevitore manda i dati, con la MLAT collegata. Subito dopo l'installazione può servire
qualche minuto. Più ricevitori dietro lo stesso indirizzo:
`flyitalyadsb-lightcone --name <nome MLAT>`.

**I miei dati arrivano?** Apri la pagina
[I miei dati arrivano?](https://flyitalyadsb.com/community/stato-feeder/?utm_source=github&utm_campaign=fly-italy-adsb)
da un dispositivo sulla rete del ricevitore. Problemi:
[contattaci](https://flyitalyadsb.com/contatti/?utm_source=github&utm_campaign=fly-italy-adsb)
o scrivi a installazione@flyitalyadsb.com.

**Rimozione:** `sudo bash /usr/local/share/flyitalyadsb/uninstall.sh`. Tiene l'UUID del
ricevitore (`/usr/local/share/flyitalyadsb/flyitalyadsb-uuid`): se reinstalli, resta lo stesso
ricevitore per Lightcone e le pagine dei feeder. Toglie anche il vecchio pacchetto di
statistiche (`flyitalyadsb-stats`), se il ricevitore ce l'ha ancora: lo sostituisce Lightcone.

</details>
