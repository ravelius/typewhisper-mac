import SwiftUI
import AVFoundation
import WhisperKit

@main
struct SaneluApp: App {
    @StateObject private var recorder = LocalDictation()

    var body: some Scene {
        WindowGroup {
            VStack(spacing: 20) {
                Text("Sanelu").font(.largeTitle.bold())
                Text(recorder.status).multilineTextAlignment(.center)
                Button(recorder.isRecording ? "Lopeta ja litteroi" : "Aloita sanelu") {
                    Task { await recorder.toggle() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(recorder.isProcessing)
                if !recorder.lastText.isEmpty {
                    ScrollView { Text(recorder.lastText).frame(maxWidth: .infinity, alignment: .leading) }
                    Button("Kopioi teksti") { UIPasteboard.general.string = recorder.lastText }
                    Text("Palaa edelliseen sovellukseen iPhonen paluulinkistä. Näppäimistö lisää tekstin kenttään.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Text("Asetukset → Yleiset → Näppäimistö → Näppäimistöt → Lisää uusi → Suomi + sanelu. Salli täysi käyttö, jotta sovellus ja näppäimistö voivat jakaa sanelutuloksen.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            .padding()
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
        else { requestID = nil; await start() }
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
            guard recorder.record() else { throw DictationError.recordingFailed }
            self.recorder = recorder
            audioURL = url
            lastText = ""
            isRecording = true
            status = "Puhu suomea ja paina lopuksi Lopeta ja litteroi."
        } catch { status = "Tallennus epäonnistui: \(error.localizedDescription)" }
    }

    private func stop() async {
        recorder?.stop()
        recorder = nil
        isRecording = false
        guard let url = audioURL else { return }
        isProcessing = true
        status = model == nil ? "Ladataan puhemallia ja litteroidaan…" : "Litteroidaan paikallisesti…"
        do {
            if model == nil {
                model = try await WhisperKit(WhisperKitConfig(model: "large-v3-v20240930_626MB"))
            }
            let result = try await model!.transcribe(audioPath: url.path)
            let text = result.map(\.text).joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            lastText = text
            if let requestID { DictationBridge.finish(text, for: requestID) }
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
