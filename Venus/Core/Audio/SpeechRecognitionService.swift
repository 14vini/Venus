//
//  SpeechRecognitionService.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation
import Speech
import AVFoundation

protocol SpeechRecognitionServiceProtocol: AnyObject {
    var isRecording: Bool { get }
    func requestPermissions()
    func startRecording(onTextRecognized: @escaping (String) -> Void, onError: @escaping (Error) -> Void) throws
    func stopRecording()
}

final class SpeechRecognitionService: SpeechRecognitionServiceProtocol {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "pt-BR"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private(set) var isRecording = false

    func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { _ in }
        AVAudioSession.sharedInstance().requestRecordPermission { _ in }
    }

    func startRecording(onTextRecognized: @escaping (String) -> Void, onError: @escaping (Error) -> Void) throws {
        if isRecording {
            stopRecording()
        }

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw VenusAIError.networkError
        }
        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                onTextRecognized(result.bestTranscription.formattedString)
            }
            if error != nil || result?.isFinal == true {
                self.stopRecording()
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        isRecording = true
    }

    func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            recognitionRequest?.endAudio()
        }
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isRecording = false

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
