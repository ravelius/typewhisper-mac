# Sanelu iOS: paikallisen Mac Studio -työn jatko

Tämä tiedosto on siirtomuistio paikalliselle Codex-sessiolle. Käyttäjä haluaa
suomenkielisen iPhone-näppäimistön, jossa on tavallinen sormin kirjoittamisen
ennakointi ja paikallinen puheesta tekstiksi -sanelu. Käytä valmiita,
ylläpidettyjä osia, kun se parantaa toteutusta. Käyttäjän Mac Studiossa on
Xcode ja Apple-kehittäjätili valmiina. Jatka toteutusta ja asenna sovellus
fyysiseen iPhoneen, jos laite on saatavilla.

## Lähtötilanne 28.9.2026

- GitHub: `ravelius/typewhisper-mac`, haara `feature/finnish-ios-keyboard`.
  iOS-projekti on tässä kansiossa. Älä muuta macOS-sovellusta ilman syytä.
- Viimeisin GitHub-commit ennen tätä muistioa: `322b9736b3010cbaf773865ab13039738191b0c3`.
- GitHub Actionsin `Sanelu iOS build` -ajo `36428107707` valmistui
  onnistuneesti: XcodeGen loi projektin ja Xcode rakensi molemmat targetit
  iOS-simulaattorille. Se ei todista toimintaa fyysisessä iPhonessa.
- `project.yml` määrittää sovelluksen `Sanelu` ja laajennuksen
  `FinnishKeyboard`. Xcode-projektia ei ole talletettu repoon; aja
  `xcodegen generate` tässä kansiossa. Asenna XcodeGen tarvittaessa.
- `App/SaneluApp.swift`: SwiftUI-kokeilukenttä, mikrofonitallennus,
  WhisperKitin `large-v3-v20240930_626MB`, tekstin jako ja asetukset.
- `Keyboard/KeyboardViewController.swift`: Å/Ä/Ö-asettelu, numerot, symbolit,
  sanaehdotukset, välilyönnillä tehtävä varovainen korjaus ja peruutus.
- `Keyboard/FinnishPrediction.swift`: UITextCheckerin suomalainen sanasto,
  pieni aloitussanasto, paikalliset sanamäärät ja sanapareista opitut
  seuraavan sanan ehdotukset. Tämä ei vielä ole QuickType-tasoinen ennustin.
- `Shared/DictationBridge.swift`: App Groupin kautta kulkeva pyyntö/tulos.
  Näppäimistölaajennus ei tallenna ääntä itse; pääsovellus tekee sen.
- Käyttäjä ei halua tilausta eikä puheen pilvilitterointia. Ensimmäinen
  puhemallin lataus tarvitsee verkkoyhteyden ja noin 626 Mt tilaa.

## Tee seuraavaksi paikallisesti

1. Tarkista haara ja puhdas Git-tila. Lue tämän kansion `README.md`.
   Asenna tai varmista XcodeGen, aja `xcodegen generate` ja avaa
   `Sanelu.xcodeproj` Xcodessa.
2. Valitse käyttäjän Apple Developer Team automaattiseen allekirjoitukseen.
   Tarkista `project.yml`-tiedoston bundle ID:t ja molempien entitlements-
   tiedostojen App Group. Ne ovat nyt `fi.klik.Sanelu`,
   `fi.klik.Sanelu.FinnishKeyboard` ja `group.fi.klik.sanelu`; varmista niiden
   saatavuus käyttäjän tilillä. Saman App Groupin pitää olla kummassakin
   targetissa. Korjaa projektin asetukset ja rekisteröinnit tarvittaessa.
3. Rakenna ensin laitteelle, sitten asenna sovellus liitettyyn iPhoneen.
   Hoida Xcoden mahdolliset allekirjoitus-, laiteluottamus- ja oikeuskehotteet
   käyttäjän kanssa. Älä kopioi kehittäjätilin salaisuuksia repoon tai lokiin.
4. Ota näppäimistö käyttöön iPhonessa ja testaa tavallinen kirjoitus:
   Å/Ä/Ö, vaihto numeroihin, välilyönti, rivinvaihto, askelpalautin,
   sanaehdotuksen valinta, korjaus ja sen peruminen. Testaa myös tilanteet,
   joissa Täysi käyttö on pois käytöstä.
5. Testaa sanelu oikealla laitteella: mikrofonilupa, ensimmäinen mallin
   lataus, suomenkielinen litterointi, paluu tekstikenttään ja tuloksen
   lisääminen kerran. `extensionContext.open` ei ole vielä vahvistettu
   fyysisessä iPhonessa. Jos iOS estää pääsovelluksen avaamisen näppäimistöstä,
   toteuta toimiva käyttäjäpolku ja dokumentoi alustan raja. Sovelluksessa on
   jo tekstin kopiointi varatienä.
6. Korjaa havaitut virheet, aja käännös uudelleen ja vie muutokset samaan
   GitHub-haaraan. Kerro käyttäjälle täsmällisesti, mikä testattiin laitteella
   ja mikä jäi vielä kesken.

Tämän pilvi-istunnon työtila oli Linux eikä sillä ollut pääsyä Mac Studion
Xcodeen, Apple-tiliin tai iPhoneen. Älä oleta laitteen testausta tehdyksi.

## Paikallisen jatkon tilanne 28.9.2026

- NAS-checkout on edelleen haarassa `feature/finnish-ios-keyboard`. Xcode 27.0 ja
  XcodeGen 2.46.0 rakentavat projektin. Simulaattoriin asennus onnistuu, kun
  myös App Group -entitlements allekirjoitetaan molempiin targetteihin.
- iPhone 18 Pro -simulaattorissa (iOS 27) on testattu Å/Ä/Ö, numerot,
  symbolisivu, välilyönti, rivinvaihto, askelpalautin, sanaehdotuksen valinta,
  `Kiitod` → `Kiitos` -korjaus ja sen välitön peruminen. Kun korjausasetus
  poistettiin sovelluksesta, `Kiitod` säilyi korjaamatta allekirjoitetussa
  App Group -simulaattorikoontiversiossa. iPhonen vaaka-asento ja iPad (A16)
  -simulaattorin pysty- ja vaaka-asento on tarkistettu visuaalisesti.
- Täysi käyttö pois käytöstä -tilassa sanelupainikkeen avaama hälytys kaatoi
  aiemmin näppäimistölaajennuksen. Ohje näkyy nyt näppäimistön ehdotusrivillä,
  ja uusi simulaattoritesti varmisti, ettei painike enää kaada laajennusta.
- Pääsovellus sai mikrofoniluvan, tallensi äänen, latasi WhisperKit-mallin ja
  litteroi testitallenteen. Tallenteen sisältö ei ollut hallittu suomenkielinen
  testilause; suomenkielisen puheen tunnistus ja paluu toisen sovelluksen
  tekstikenttään ovat edelleen vahvistamatta. Mallin kieli on asetettu `fi`.
- App Store Connect -jakeluun allekirjoitettu `0.1.0 (1)` -IPA on NASissa
  polussa `/Volumes/NAS-Homes/koodaus/Chat GPT/Näppis/builds/Sanelu-0.1.0-b1.ipa`.
  `codesign --verify --deep --strict` meni läpi, ja sovelluksen sekä
  laajennuksen jakeluprofiileissa on `group.fi.klik.sanelu`. Tämä ei vielä
  tarkoita, että versio olisi ladattu TestFlightiin.
- Xcode-tilillä oleva Apple Development -varmenne ei sisällä tämän koneen
  avainparia. Jakelu-IPA onnistui tekemällä allekirjoittamaton arkisto,
  lisäämällä arkistoon molempien targettien App Group -oikeudet ad hoc
  -allekirjoituksella ja viemällä arkisto Xcoden automaattisella
  App Store Connect -allekirjoituksella. Kehitysvarmennetta ei peruutettu.
- TestFlight-lähetys pysähtyi virheeseen: App Store Connectista puuttuu
  `fi.klik.Sanelu`-sovellustietue. App Store Connect pyytää erillistä
  selainkirjautumista. Luo tietue ja lähetä sen jälkeen paketti; tarkista
  käsittely sekä sisäisen testaajaryhmän saatavuus erikseen.
