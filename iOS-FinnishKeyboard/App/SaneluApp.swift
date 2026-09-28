import SwiftUI
import AVFoundation
import WhisperKit

@main
struct SaneluApp: App {
    @StateObject private var recorder = LocalDictation()
    @State private var sampleText = ""
    @AppStorage(DictationBridge.learningKey, store: DictationBridge.store) private var learningEnabled = true
    @AppStorage(DictationBridge.autocorrectKey, store: DictationBridge.store) private var autocorrectEnabled = true

    var body: some Scene {
        WindowGroup {
            ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Sanelu").font(.largeTitle.bold())
                Text("Suomalainen näppäimistö ja paikallinen sanelu.")
                    .foregroundStyle(.secondary)
                GroupBox("Kokeile näppäimistöä") {
                    TextEditor(text: $sampleText)
                        .frame(minHeight: 90)
                        .accessibilityLabel("Kirjoituksen kokeilukenttä")
                }
                Text(recorder.status).multilineTextAlignment(.center)
                Button(recorder.isRecording ? "Lopeta ja litteroi" : "Aloita sanelu") {
                    Task { await recorder.toggle() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(recorder.isProcessing)
                if !recorder.lastText.isEmpty {
                    ScrollView { Text(recorder.lastText).frame(maxWidth: .infinity, alignment: .leading) }
                    Button("Kopioi teksti") { UIPasteboard.general.string = recorder.lastText }
                    ShareLink(item: recorder.lastText) { Text("Jaa teksti") }
                    Text("Palaa edelliseen sovellukseen iPhonen paluulinkistä. Näppäimistö lisää tekstin kenttään.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Text("Asetukset → Yleiset → Näppäimistö → Näppäimistöt → Lisää uusi → Suomi + sanelu. Salli täysi käyttö, jotta sovellus ja näppäimistö voivat jakaa sanelutuloksen.")
                    .font(.footnote).foregroundStyle(.secondary)
                GroupBox("Kirjoittamisen asetukset") {
                    VStack(alignment: .leading) {
                        Toggle("Opi kirjoittamiani sanoja", isOn: $learningEnabled)
                        Toggle("Korjaa selvät virheet välilyönnillä", isOn: $autocorrectEnabled)
                        Text("Opitut sanat pysyvät tällä laitteella. Korjauksen voi perua heti askelpalauttimella.")
                            .font(.footnote).foregroundStyle(.secondary)
                        Button("Tyhjennä opittu sanasto", role: .destructive) {
                            DictationBridge.store?.removeObject(forKey: "prediction.word.counts")
                            DictationBridge.store?.removeObject(forKey: "prediction.next.counts")
                        }
                    }
                }
            }
            .padding()
            }
            .onOpenURL { url in
                guard url.scheme == "klik-sanelu", url.host == "record" else { return }
                Task { await recorder.startFromKeyboard() }
            }
        }
    }
}

@MainActor
final class LocalDictation: ObservableObject {
    @Published var status = "Ensimmäinen sanelu lataa puhemallin. Sen jälkeen tunnistus toimii ilman verkkoyhteyttä."
    @Published var lastText = ""
    @Published var isRecording = false
    @Published var isProcessing = false

    private var recorder: AVAudioRecorder?
    private var audioURL: URL?
    private var requestID: String?
    private var model: WhisperKit?

    func startFromKeyboard() async {
        guard !isRecording && !isProcessing else { return }
        requestID = DictationBridge.currentRequest
        await start()
    }

    func toggle() async {
        if isRecording { await stop() }
        else { requestID = DictationBridge.currentRequest; await start() }
    }

    private func microphonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { continuation.resume(returning: $0) }
        }
    }

    private func start() async {
        guard await microphonePermission() else {
            status = "Anna mikrofonilupa iPhonen asetuksissa."
            return
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .default)
            try session.setActive(true)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
            let recorder = try AVAudioRecorder(url: url, settings: [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 16_000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ])
            recorder.prepareToRecord()
            guard recorder.record() else { throw DictationError.recordingFailed }
            self.recorder = recorder
            audioURL = url
            lastText = ""
            isRecording = true
            status = "Puhu suomea ja paina lopuksi Lopeta ja litteroi."
        } catch {
            status = "Tallennus epäonnistui: \(error.localizedDescription)"
            try? AVAudioSession.sharedInstance().setActive(false)
        }
    }

    private func stop() async {
        recorder?.stop()
        recorder = nil
        isRecording = false
        guard let url = audioURL else { return }
        audioURL = nil
        let activeRequest = requestID
        requestID = nil
        isProcessing = true
        status = model == nil ? "Ladataan puhemallia ja litteroidaan…" : "Litteroidaan paikallisesti…"
        do {
            if model == nil {
                model = try await WhisperKit(WhisperKitConfig(model: "large-v3-v20240930_626MB"))
            }
            let result = try await model!.transcribe(
                audioPath: url.path,
                decodeOptions: DecodingOptions(language: "fi")
            )
            let text = result.map(\.text).joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            lastText = text
            if let activeRequest { DictationBridge.finish(text, for: activeRequest) }
            status = text.isEmpty ? "Puhetta ei tunnistettu. Kokeile uudelleen." : "Valmis. Palaa tekstikenttään."
        } catch { status = "Litterointi epäonnistui: \(error.localizedDescription)" }
        try? FileManager.default.removeItem(at: url)
        try? AVAudioSession.sharedInstance().setActive(false)
        isProcessing = false
    }
}

private enum DictationError: LocalizedError {
    case recordingFailed
    var errorDescription: String? { "Mikrofoni ei käynnistynyt." }
}
