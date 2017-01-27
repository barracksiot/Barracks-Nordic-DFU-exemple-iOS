# Barracks + Nordic DFU exemple #

This  exemple app shows you how to push an update from [Barracks](https://barracks.io/) to a [Nordic NRF52](https://www.nordicsemi.com/Products/nRF52-Series-SoC) board using the Barracks SDK and the Nordic DFU Library

![alt tag](https://www.nordicsemi.com/var/ezwebin_site/storage/images/news/news-releases/product-related-news/nordic-nrf52-series-redefines-single-chip-bluetooth-smart-by-marrying-barrier-breaking-performance-and-power-efficiency-with-on-chip-nfc-for-touch-to-pair/1479174-2-eng-GB/Nordic-nRF52-Series-redefines-single-chip-Bluetooth-Smart-by-marrying-barrier-breaking-performance-and-power-efficiency-with-on-chip-NFC-for-Touch-to-Pair.jpg)


## You should take a look at : ##
* The [iOS Barracks SDK](https://github.com/barracksiot/ios-osx-client)
* The [Nordic iOSDFULibrary](https://github.com/NordicSemiconductor/IOS-Pods-DFU-Library)

## Setup ##

* Download the source code
* run ```pod install```
 in a terminal at the root of the project
* Open the newly created ```.xcworkspace``` and begin working on your project.

## Using Barracks and Nordic ##

* Don't forget to enter your API key in the BarracksHelper init

## How it works ? ##

* 1 : Find the advertising NRF52 by scanning bluetooth device
* 2 : Once we found the device, let use Barracks to check if an update is available for the versionID we wrote.
* 3 : If an update is available, let's proceed to the installation by downloading update using BarracksHelper then push it on the NRF52 to update the firmware using the Nordic DFU Library.
