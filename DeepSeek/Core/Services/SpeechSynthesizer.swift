//
//  SpeechSynthesizer.swift
//  DeepSeek
//
//  Created by Harlans on 2024/12/5.
//

import Foundation
import AVFoundation
import SwiftUI


class SpeechSynthesizerDelegate: NSObject, AVSpeechSynthesizerDelegate {
    var onSpeechFinished: (() -> Void)?
    var onSpeechStart: (() -> Void)?
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onSpeechFinished?()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        onSpeechStart?()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didReceiveError error: Error, for utterance: AVSpeechUtterance, at characterIndex: UInt) {
        print("Speech synthesis error: \(error)")
    }
}

@MainActor
final class SpeechSynthesizer: NSObject, ObservableObject {
    static let shared = SpeechSynthesizer()
    private let synthesizer = AVSpeechSynthesizer()
    private let delegate = SpeechSynthesizerDelegate()
    
    @Published var isSpeaking = false
    @Published var voices: [AVSpeechSynthesisVoice] = []
    
    override init() {
        super.init()
        synthesizer.delegate = delegate
        fetchVoices()
    }
    
    func getVoiceIdentifier() -> String? {
        let voiceIdentifier = UserDefaults.standard.string(forKey: "voiceIdentifier")
        if let voice = voices.first(where: {$0.identifier == voiceIdentifier}) {
            return voice.identifier
        }
        
        return voices.first?.identifier
    }
    
    var lastCancelation: (()->Void)? = {}
    
    func speak(text: String, onFinished: @escaping () -> Void = {}) async {
        guard let voiceIdentifier = getVoiceIdentifier() else {
            print("could not find identifier")
            return
        }
        
        print("selected", voiceIdentifier)
        
        let audioSession = AVAudioSession()
        do {
            try audioSession.setCategory(.playback, mode: .default, options: .duckOthers)
            try audioSession.setActive(false)
        } catch let error {
            print("❓", error.localizedDescription)
        }
        
        lastCancelation = onFinished
        delegate.onSpeechFinished = {
            withAnimation {
                self.isSpeaking = false
            }
            onFinished()
        }
        delegate.onSpeechStart = {
            withAnimation {
                self.isSpeaking = true
            }
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(identifier: voiceIdentifier)
        utterance.rate = 0.5
        synthesizer.speak(utterance)
        
        let voices = AVSpeechSynthesisVoice.speechVoices()
        voices.forEach { voice in
            print("\(voice.identifier) - \(voice.name)")
        }
    }
    
    func stopSpeaking() async {
        withAnimation {
            isSpeaking = false
        }
        lastCancelation?()
        synthesizer.stopSpeaking(at: .immediate)
    }
    
    
    func fetchVoices() {
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        
        let sortedVoices = allVoices.sorted { (firstVoice: AVSpeechSynthesisVoice, secondVoice: AVSpeechSynthesisVoice) -> Bool in
            if firstVoice.language.hasPrefix("zh") && !secondVoice.language.hasPrefix("zh") {
                return true
            } else if !firstVoice.language.hasPrefix("zh") && secondVoice.language.hasPrefix("zh") {
                return false
            }
            return firstVoice.quality.rawValue > secondVoice.quality.rawValue
        }
        
        let diff = self.voices.elementsEqual(sortedVoices, by: { $0.identifier == $1.identifier })
        if diff {
            return
        }
        
        DispatchQueue.main.async {
            self.voices = sortedVoices
        }
    }
}
