import AVFoundation
import Foundation
import Observation
import Speech

/// Listens through the mic and transcribes on the iPhone, stopping on its own after a pause.
@Observable
final class SpeechListener {
    enum State: Equatable {
        case idle, listening, needsPermission, unavailable
    }

    private(set) var state: State = .idle
    private(set) var transcript = ""

    @ObservationIgnored private var engine: AVAudioEngine?
    @ObservationIgnored private var request: SFSpeechAudioBufferRecognitionRequest?
    @ObservationIgnored private var task: SFSpeechRecognitionTask?
    @ObservationIgnored private var silenceTimer: Task<Void, Never>?
    @ObservationIgnored private var limitTimer: Task<Void, Never>?
    @ObservationIgnored private var onFinish: ((String) -> Void)?

    /// Stops after this long without new words, or this long before any words.
    private static let pause: Duration = .seconds(1.5)
    private static let waitForSpeech: Duration = .seconds(5)
    private static let longest: Duration = .seconds(15)

    /// Starts listening. `onFinish` gets whatever was heard, possibly empty.
    func start(hints: [String], onFinish: @escaping (String) -> Void) async {
        guard state != .listening else { return }
        guard await Self.authorize() else {
            state = .needsPermission
            return
        }
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")), recognizer.isAvailable else {
            state = .unavailable
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            request.contextualStrings = hints
            if recognizer.supportsOnDeviceRecognition {
                request.requiresOnDeviceRecognition = true
            }

            let engine = AVAudioEngine()
            Self.installTap(on: engine.inputNode, feeding: request)
            engine.prepare()
            try engine.start()

            self.engine = engine
            self.request = request
            self.onFinish = onFinish
            transcript = ""
            state = .listening

            task = Self.recognize(with: recognizer, request: request) { [weak self] text, done in
                Task { @MainActor in self?.heard(text, done: done) }
            }
            restartSilenceTimer(after: Self.waitForSpeech)
            limitTimer = Task { [weak self] in
                try? await Task.sleep(for: Self.longest)
                guard !Task.isCancelled else { return }
                self?.stop()
            }
        } catch {
            teardown()
            state = .unavailable
        }
    }

    /// Stops listening and hands over what was heard.
    func stop() {
        guard state == .listening else { return }
        let text = transcript
        let finish = onFinish
        teardown()
        state = .idle
        finish?(text)
    }

    private func heard(_ text: String?, done: Bool) {
        guard state == .listening else { return }
        if let text, !text.isEmpty, text != transcript {
            transcript = text
            restartSilenceTimer(after: Self.pause)
        }
        if done {
            stop()
        }
    }

    private func restartSilenceTimer(after delay: Duration) {
        silenceTimer?.cancel()
        silenceTimer = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            self?.stop()
        }
    }

    private func teardown() {
        silenceTimer?.cancel()
        limitTimer?.cancel()
        silenceTimer = nil
        limitTimer = nil
        engine?.stop()
        engine?.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        engine = nil
        request = nil
        task = nil
        onFinish = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // Audio and recognition callbacks arrive on background threads, so they're set up
    // outside the main actor and hop back to it.

    nonisolated private static func authorize() async -> Bool {
        let speech = await withCheckedContinuation { (continuation: CheckedContinuation<SFSpeechRecognizerAuthorizationStatus, Never>) in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
        guard speech == .authorized else { return false }
        return await AVAudioApplication.requestRecordPermission()
    }

    nonisolated private static func installTap(on input: AVAudioInputNode,
                                               feeding request: SFSpeechAudioBufferRecognitionRequest) {
        let format = input.outputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }
    }

    nonisolated private static func recognize(with recognizer: SFSpeechRecognizer,
                                              request: SFSpeechAudioBufferRecognitionRequest,
                                              update: @escaping @Sendable (String?, Bool) -> Void) -> SFSpeechRecognitionTask {
        recognizer.recognitionTask(with: request) { result, error in
            update(result?.bestTranscription.formattedString, (result?.isFinal ?? false) || error != nil)
        }
    }
}
