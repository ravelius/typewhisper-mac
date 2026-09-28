import UIKit

/// Uses the Finnish system spelling lexicon when present, with a small local fallback.
/// Learned words remain on the device in the keyboard's shared app group.
final class FinnishPrediction {
    private let checker = UITextChecker()
    private let store = DictationBridge.store
    private let key = "prediction.word.counts"
    private let pairKey = "prediction.next.counts"
    private let language: String? = UITextChecker.availableLanguages.first {
        $0.lowercased().replacingOccurrences(of: "-", with: "_").hasPrefix("fi")
    }
    private let basics = "minä sinä hän me te he tämä tuossa täällä tänään huomenna eilen kyllä kiitos hei moi hyvää huomenta iltaa näkemiin miten miksi milloin missä mikä kuka olisi voisitko voisin voimme tulee olen olet on ovat oli olivat haluan haluaisin tarvitsen tarvitaan pitää pitäisi tehdä mennä tulla katsoa nähdä sanoa kysyä vastata kirjoittaa kuvata kuva valokuva kuvaus studio asiakas työ koti kauppa koulu koira aika päivä viikko kuukausi vuosi nyt sitten vielä myös paljon vähän todella aika hyvä hieno paras uusi vanha oikea väärä sama toinen ensimmäinen seuraava siitä tähän tänne sinne kanssa ilman jotta koska mutta tai että jos kun niin ei en et ole ollut voisi ehkä varmaan varmasti tämäkin niitä niitäkin nämä nuo siellä täällä mikäli kanssa minulla sinulla hänellä meidän teidän heidän minun sinun hänen meidän myös vielä oikein väärin valmis voidaan voisi tekemään tekeminen käytän käytössä kiitos paljon palaan takaisin pian odotan haluan haluaisin tehdä jotain muuta vastaus viesti sähköposti muistiinpano asia asiat kuvaus kuvaamaan kameralla suomeksi englanniksi teksti kirjoitan kirjoittaa kirjoittaminen sanelu sanelee sanelemaan".split(separator: " ").map(String.init)

    func learn(_ word: String, after previous: String? = nil) {
        guard store?.object(forKey: DictationBridge.learningKey) as? Bool ?? true else { return }
        let normalized = word.lowercased(with: Locale(identifier: "fi_FI"))
        guard normalized.count >= 2, normalized.count <= 32,
              normalized.unicodeScalars.allSatisfy({ CharacterSet.letters.contains($0) }) else { return }
        var counts = store?.dictionary(forKey: key) as? [String: Int] ?? [:]
        counts[normalized, default: 0] += 1
        if counts.count > 2_000 {
            let sorted = counts.sorted { $0.value > $1.value }.prefix(1_500)
            counts = Dictionary(uniqueKeysWithValues: sorted.map { ($0.key, $0.value) })
        }
        store?.set(counts, forKey: key)
        if let previous, !previous.isEmpty {
            var pairs = store?.dictionary(forKey: pairKey) as? [String: Int] ?? [:]
            let pair = previous.lowercased(with: Locale(identifier: "fi_FI")) + " " + normalized
            pairs[pair, default: 0] += 1
            if pairs.count > 3_000 {
                pairs = Dictionary(uniqueKeysWithValues: pairs.sorted { $0.value > $1.value }
                    .prefix(2_000).map { ($0.key, $0.value) })
            }
            store?.set(pairs, forKey: pairKey)
        }
    }

    /// Correct only an unambiguous, one-character Finnish spelling error.
    /// The original spelling is preserved by the keyboard for immediate undo.
    func correction(for word: String) -> String? {
        guard word.count >= 3, let language else { return nil }
        let range = NSRange(location: 0, length: (word as NSString).length)
        let misspelled = checker.rangeOfMisspelledWord(in: word, range: range,
            startingAt: 0, wrap: false, language: language)
        guard misspelled.location != NSNotFound else { return nil }
        let lower = word.lowercased(with: Locale(identifier: "fi_FI"))
        let candidates = checker.guesses(forWordRange: range, in: word, language: language) ?? []
        guard let candidate = candidates.first(where: {
            let proposed = $0.lowercased(with: Locale(identifier: "fi_FI"))
            return proposed.first == lower.first && proposed != lower &&
                proposed.count == lower.count &&
                zip(proposed, lower).filter { $0.0 != $0.1 }.count == 1
        }) else { return nil }
        return word.first?.isUppercase == true
            ? candidate.prefix(1).uppercased() + String(candidate.dropFirst()) : candidate
    }

    func suggestions(for typedPrefix: String, after previous: String? = nil) -> [String] {
        let prefix = typedPrefix.lowercased(with: Locale(identifier: "fi_FI"))
        let counts = store?.dictionary(forKey: key) as? [String: Int] ?? [:]
        if prefix.isEmpty {
            guard let previous else { return [] }
            let pairs = store?.dictionary(forKey: pairKey) as? [String: Int] ?? [:]
            let start = previous.lowercased(with: Locale(identifier: "fi_FI")) + " "
            return pairs.filter { $0.key.hasPrefix(start) }
                .sorted { $0.value > $1.value }
                .prefix(3).map { String($0.key.dropFirst(start.count)) }
        }
        var candidates = counts.keys.filter { $0.hasPrefix(prefix) && $0 != prefix }
        candidates += basics.filter { $0.hasPrefix(prefix) && $0 != prefix }
        if let language {
            let range = NSRange(location: 0, length: (prefix as NSString).length)
            candidates += checker.completions(forPartialWordRange: range, in: prefix, language: language) ?? []
            if prefix.count >= 3 {
                candidates += checker.guesses(forWordRange: range, in: prefix, language: language) ?? []
            }
        }
        let unique = Array(Set(candidates)).filter { $0.lowercased() != prefix }
        return unique.sorted {
            let a = counts[$0, default: 0], b = counts[$1, default: 0]
            if a != b { return a > b }
            if $0.hasPrefix(prefix) != $1.hasPrefix(prefix) { return $0.hasPrefix(prefix) }
            if $0.count != $1.count { return $0.count < $1.count }
            return $0.localizedStandardCompare($1) == .orderedAscending
        }.prefix(3).map { candidate in
            typedPrefix.first?.isUppercase == true ? candidate.prefix(1).uppercased() + String(candidate.dropFirst()) : candidate
        }
    }
}
