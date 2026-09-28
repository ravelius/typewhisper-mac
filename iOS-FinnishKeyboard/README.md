# Sanelu – suomalainen iOS-näppäimistö ja paikallinen puheentunnistus

Kokeiltava lähdekoodiversio. Sisältää Å/Ä/Ö-näppäimet, numerot, symbolit,
sanaehdotukset, opitun sanaston sekä WhisperKit-pohjaisen puheen tekstiksi
-toiminnon. Ei tilausta eikä puheen pilvilitterointia. Ensimmäinen mallin
lataus tarvitsee verkkoyhteyden ja noin 626 Mt tilaa.

## Rakennus Macilla

1. Asenna Xcode 16+ ja [XcodeGen](https://github.com/yonaskolb/XcodeGen).
2. Vaihda `project.yml`-tiedoston bundle ID:t sekä molempien entitlements-
   tiedostojen App Group omiin tunnuksiisi. Aseta Xcodessa oma Apple Developer
   Team. App Groupin pitää olla täsmälleen sama molemmissa targeteissa.
3. Aja `xcodegen generate` tässä kansiossa ja avaa `Sanelu.xcodeproj`.
4. Rakenna ja asenna fyysiseen iPhoneen. Lisää näppäimistö iPhonen
   asetuksista ja salli Täysi käyttö, jotta laajennus ja pääsovellus voivat
   jakaa tuloksen App Groupin kautta.
5. Avaa sovellus kerran. Sanele tekstikentässä valitsemalla tämä näppäimistö,
   paina 🎙, tallenna puhe ja pysäytä. Palaa iOS:n paluulinkistä alkuperäiseen
   sovellukseen; näppäimistö lisää valmiin tekstin.

## Käytetyt valmiit osat ja rajat

- [Argmax OSS / WhisperKit](https://github.com/argmaxinc/argmax-oss-swift)
  hoitaa paikallisen tunnistuksen. Malli `large-v3-v20240930_626MB` sopii
  monikieliseen iOS-käyttöön. Pilvipalvelua ei kutsuta litterointiin.
- iOS:n `UITextChecker` antaa suomen sanakirjan täydennyksiä ja
  kirjoitusasu-ehdotuksia **jos** laitteessa on vastaava kielisanasto.
  Lisäksi näppäimistöllä on pieni aloitussanasto ja paikallisesti opitut sanat
  sekä aiempien kirjoitusten sanapareista opitut seuraavan sanan ehdotukset.
- Automaattinen korjaus, pyyhkäisykirjoitus ja emoji-valitsin puuttuvat.
  Sanapareihin perustuva seuraavan sanan ennustus ei vielä vastaa QuickTypea. Tämä on
  ensimmäinen ennakoivan kirjoittamisen toteutus, ei täysi QuickType-kopio.
- Näppäimistölaajennus ei voi käyttää mikrofonia. Pääsovellus tallentaa ja
  litteroi; tulos siirtyy App Groupissa takaisin näppäimistöön. iOS:n
  `extensionContext.open`-kutsun toiminta ja paluu alkuperäiseen sovellukseen
  pitää tarkistaa oikealla laitteella. Jos avaaminen estyy, avaa sovellus käsin.
- Kolmannen osapuolen näppäimistöt eivät näy salasanakentissä eivätkä
  sovelluksissa, jotka estävät ne erikseen.

TypeWhisperin julkinen lähdekoodi on **macOS-sovellus**. iOS-lähdekoodi on
yksityinen, joten tämä iOS-projekti ei väitä olevansa sen fork. Mac-versioon
voi myöhemmin tehdä oman haaran erikseen GPLv3-lisenssiä noudattaen.
