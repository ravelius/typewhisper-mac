# Sanelu – suomalainen iOS-näppäimistö ja paikallinen puheentunnistus

Kokeiltava iPhone-sovellus ja näppäimistölaajennus. Sisältää Å/Ä/Ö-näppäimet,
numerot, symbolit, napautettavat sanaehdotukset, paikallisesti opitun sanaston,
varovaisen kirjoitusvirheiden korjauksen sekä WhisperKit-pohjaisen puheen
tekstiksi -toiminnon. Sovelluksessa on oma kokeilukenttä, tekstin kopiointi ja
jako sekä asetukset oppimiselle ja automaattiselle korjaukselle. Ei tilausta
eikä puheen pilvilitterointia. Ensimmäinen mallin lataus tarvitsee
verkkoyhteyden ja noin 626 Mt tilaa.

## Rakennus Macilla

1. Asenna Xcode 16+ ja [XcodeGen](https://github.com/yonaskolb/XcodeGen).
2. Vaihda `project.yml`-tiedoston bundle ID:t sekä molempien entitlements-
   tiedostojen App Group omiin tunnuksiisi. Aseta Xcodessa oma Apple Developer
   Team. App Groupin pitää olla täsmälleen sama molemmissa targeteissa.
3. Aja `xcodegen generate` tässä kansiossa ja avaa `Sanelu.xcodeproj`.
4. Rakenna ja asenna fyysiseen iPhoneen. Lisää näppäimistö iPhonen
   asetuksista ja salli Täysi käyttö, jotta laajennus ja pääsovellus voivat
   jakaa tuloksen App Groupin kautta.
5. Avaa Sanelu-sovellus ja kokeile näppäimistöä sovelluksen tekstikentässä.
   Sanele painamalla näppäimistön 🎙-painiketta, tallenna puhe ja pysäytä.
   Palaa alkuperäiseen sovellukseen ja tekstikenttään: näppäimistö lisää
   valmiin tekstin. Jos iOS estää sovelluksen avaamisen laajennuksesta,
   avaa Sanelu itse ja kopioi valmis teksti.

GitHub Actionsin `Sanelu iOS build` tarkistaa lähdekoodin käännöksen
iOS-simulaattorille. Se ei tee asennettavaa, allekirjoitettua iPhone-versiota.

## Käytetyt valmiit osat ja rajat

- [Argmax OSS / WhisperKit](https://github.com/argmaxinc/argmax-oss-swift)
  hoitaa paikallisen tunnistuksen. Malli `large-v3-v20240930_626MB` sopii
  monikieliseen iOS-käyttöön. Pilvipalvelua ei kutsuta litterointiin.
- iOS:n `UITextChecker` antaa suomen sanakirjan täydennyksiä ja
  kirjoitusasu-ehdotuksia **jos** laitteessa on vastaava kielisanasto.
  Lisäksi näppäimistöllä on pieni aloitussanasto ja paikallisesti opitut sanat
  sekä aiempien kirjoitusten sanapareista opitut seuraavan sanan ehdotukset.
- Automaattinen korjaus koskee vain yhden kirjaimen selviä virheitä, kun
  laitteessa on suomen oikolukusanasto. Se tapahtuu välilyönnillä, ja sen voi
  perua heti askelpalauttimella tai poistaa asetuksista. Pyyhkäisykirjoitus ja
  emoji-valitsin puuttuvat. Sanapareihin perustuva seuraavan sanan ennustus ei
  vielä vastaa QuickTypea.
- Näppäimistölaajennus ei voi käyttää mikrofonia. Pääsovellus tallentaa ja
  litteroi; tulos siirtyy App Groupissa takaisin näppäimistöön. iOS:n
  `extensionContext.open`-kutsun toiminta ja paluu alkuperäiseen sovellukseen
  pitää tarkistaa oikealla laitteella. Jos avaaminen estyy, avaa sovellus käsin.
- Kolmannen osapuolen näppäimistöt eivät näy salasanakentissä eivätkä
  sovelluksissa, jotka estävät ne erikseen.

Tämä iOS-toteutus on uusi kansio TypeWhisperin julkisen macOS-repositorion
forkissa. TypeWhisperin yksityistä iOS-lähdekoodia ei käytetä.
