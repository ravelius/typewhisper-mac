import UIKit

final class KeyboardViewController: UIInputViewController {
    private enum Page { case letters, numbers, symbols }
    private var page: Page = .letters
    private var shifted = false
    private let prediction = FinnishPrediction()
    private let suggestionRow = UIStackView()
    private let keys = UIStackView()
    private var pendingRequest: String?
    private var pollTimer: Timer?
    private var heightConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemGray5
        hasDictationKey = true
        setup()
        render()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        pendingRequest = DictationBridge.currentRequest
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { [weak self] _ in
            self?.checkResult()
        }
        checkResult()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pollTimer?.invalidate()
        pollTimer = nil
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        if before.isEmpty || before.hasSuffix(". ") || before.hasSuffix("! ") || before.hasSuffix("? ") {
            shifted = true
            if page == .letters { render(); return }
        }
        updateSuggestions()
    }

    private func setup() {
        suggestionRow.axis = .horizontal
        suggestionRow.distribution = .fillEqually
        suggestionRow.spacing = 4
        keys.axis = .vertical
        keys.distribution = .fillEqually
        keys.spacing = 6
        let root = UIStackView(arrangedSubviews: [suggestionRow, keys])
        root.axis = .vertical
        root.spacing = 7
        root.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(root)
        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            root.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            root.topAnchor.constraint(equalTo: view.topAnchor, constant: 5),
            root.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -5),
            suggestionRow.heightAnchor.constraint(equalToConstant: 35)
        ])
        heightConstraint = view.heightAnchor.constraint(equalToConstant: 276)
        heightConstraint?.priority = .defaultHigh
        heightConstraint?.isActive = true
    }

    private func render() {
        keys.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let rows: [[String]]
        switch page {
        case .letters:
            rows = [Array("qwertyuiopå").map(String.init),
                    Array("asdfghjklöä").map(String.init),
                    ["⇧"] + Array("zxcvbnm").map(String.init) + ["⌫"],
                    ["123", "🌐", ",", "välilyönti", ".", "🎙", "↵"]]
        case .numbers:
            rows = [["1","2","3","4","5","6","7","8","9","0"],
                    ["-","/",":",";","(",")","€","&","@","\""],
                    ["#+=",".",",","?","!","'","⌫"],
                    ["ABC", "🌐", ",", "välilyönti", ".", "🎙", "↵"]]
        case .symbols:
            rows = [["[","]","{","}","#","%","^","*","+","="],
                    ["_","\\","|","~","<",">","$","£","¥","•"],
                    ["123",".",",","?","!","'","⌫"],
                    ["ABC", "🌐", ",", "välilyönti", ".", "🎙", "↵"]]
        }
        for row in rows {
            let stack = UIStackView()
            stack.axis = .horizontal
            stack.distribution = .fill
            stack.spacing = 3
            for key in row {
                let button = makeKey(key)
                stack.addArrangedSubview(button)
                let weight: CGFloat = key == "välilyönti" ? 5 : (key == "🎙" ? 1.25 : 1)
                button.widthAnchor.constraint(equalTo: stack.widthAnchor, multiplier: weight / totalWeight(row), constant: -3).isActive = true
            }
            keys.addArrangedSubview(stack)
        }
        updateSuggestions()
    }

    private func totalWeight(_ row: [String]) -> CGFloat {
        row.reduce(0) { $0 + ($1 == "välilyönti" ? 5 : ($1 == "🎙" ? 1.25 : 1)) }
    }

    private func makeKey(_ key: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(shifted && key.count == 1 ? key.uppercased() : key, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: key == "välilyönti" ? 13 : 20)
        button.backgroundColor = ["⇧","⌫","123","ABC","#+=","🌐","🎙","↵"].contains(key) ? .systemGray3 : .white
        button.layer.cornerRadius = 5
        button.accessibilityLabel = key == "🎙" ? "Sanele" : key
        button.addAction(UIAction { [weak self] _ in self?.press(key) }, for: .touchUpInside)
        if key == "⌫" {
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(repeatBackspace(_:)))
            longPress.minimumPressDuration = 0.4
            button.addGestureRecognizer(longPress)
        }
        return button
    }

    @objc private func repeatBackspace(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began || gesture.state == .changed {
            textDocumentProxy.deleteBackward()
            updateSuggestions()
        }
    }

    private func press(_ key: String) {
        switch key {
        case "⇧": shifted.toggle(); render()
        case "⌫": textDocumentProxy.deleteBackward(); updateSuggestions()
        case "123": page = .numbers; render()
        case "#+=": page = .symbols; render()
        case "ABC": page = .letters; render()
        case "🌐": advanceToNextInputMode()
        case "🎙": beginDictation()
        case "välilyönti": commitCurrentWord(); textDocumentProxy.insertText(" "); shifted = false; render()
        case "↵": commitCurrentWord(); textDocumentProxy.insertText("\n"); shifted = true; render()
        default:
            if ".!?".contains(key) { commitCurrentWord() }
            textDocumentProxy.insertText(shifted ? key.uppercased() : key)
            if key.count == 1 && key.first?.isLetter == true { shifted = false }
            if ".!?".contains(key) { shifted = true }
            render()
        }
    }

    private var currentWord: String {
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        return String(before.reversed().prefix { $0.isLetter || $0 == "-" }.reversed())
    }

    private func commitCurrentWord() {
        let word = currentWord
        if !word.isEmpty { prediction.learn(word, after: previousWord(beforeCurrent: true)) }
    }

    private func previousWord(beforeCurrent: Bool) -> String? {
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        let trimmed: String
        if beforeCurrent {
            trimmed = String(before.dropLast(currentWord.count)).trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            trimmed = before.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let value = String(trimmed.reversed().prefix { $0.isLetter || $0 == "-" }.reversed())
        return value.isEmpty ? nil : value
    }

    private func updateSuggestions() {
        suggestionRow.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let word = currentWord
        let suggestions = prediction.suggestions(for: word,
            after: word.isEmpty ? previousWord(beforeCurrent: false) : previousWord(beforeCurrent: true))
        for value in suggestions {
            let button = UIButton(type: .system)
            button.setTitle(value, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 16)
            button.backgroundColor = UIColor.systemGray6
            button.layer.cornerRadius = 5
            button.addAction(UIAction { [weak self] _ in self?.choose(value) }, for: .touchUpInside)
            suggestionRow.addArrangedSubview(button)
        }
        if suggestions.isEmpty {
            let label = UILabel()
            label.text = pendingRequest == nil ? "suomi · ä ö å" : "Palaa tähän sanelun jälkeen"
            label.textAlignment = .center
            label.textColor = .secondaryLabel
            suggestionRow.addArrangedSubview(label)
        }
    }

    private func choose(_ suggestion: String) {
        let precedingWord = previousWord(beforeCurrent: !currentWord.isEmpty)
        for _ in currentWord { textDocumentProxy.deleteBackward() }
        textDocumentProxy.insertText(suggestion + " ")
        prediction.learn(suggestion, after: precedingWord)
        shifted = false
        render()
    }

    private func beginDictation() {
        guard hasFullAccess, DictationBridge.store != nil else {
            showMessage("Salli näppäimistön Täysi käyttö asetuksissa sanelua varten.")
            return
        }
        pendingRequest = DictationBridge.request()
        updateSuggestions()
        guard let url = URL(string: "klik-sanelu://record") else { return }
        extensionContext?.open(url) { [weak self] success in
            if !success {
                DispatchQueue.main.async { self?.showMessage("Avaa Sanelu-sovellus ja aloita sanelu siellä.") }
            }
        }
    }

    private func showMessage(_ message: String) {
        let alert = UIAlertController(title: "Sanelu", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func checkResult() {
        guard let pendingRequest, let text = DictationBridge.takeResult(for: pendingRequest) else { return }
        textDocumentProxy.insertText(text)
        self.pendingRequest = nil
        updateSuggestions()
    }
}
