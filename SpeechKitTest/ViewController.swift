//
//  ViewController.swift
//  SpeechKitTest
//
//  Created by Ivan Smetanin on 15/04/2017.
//  Copyright © 2017 Ivan Smetanin. All rights reserved.
//

import UIKit
import Speech

final class ViewController: UIViewController {

    // MARK: IBOutlets

    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var resultTextView: UITextView!

    // MARK: Constants

    private let audioEngine = AVAudioEngine()
    private let request: SFSpeechAudioBufferRecognitionRequest = SFSpeechAudioBufferRecognitionRequest()
    private let audioBus: AVAudioNodeBus = 0
    private let bufferSize: AVAudioFrameCount = 1024

    // MARK: Properties

    private var speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
    private var recognitionTask: SFSpeechRecognitionTask?
    private var isRecognitionRunning: Bool = false {
        didSet {
            if isRecognitionRunning {
                startStopButton.setTitle("Stop", for: UIControlState())
            } else {
                startStopButton.setTitle("Start", for: UIControlState())
            }
        }
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: Internal helpers

    func timerEnded() {
        debugPrint(#function)
        stopRecordingAndRecognition()
    }

    // MARK: IBActions

    @IBAction func startStopButtonTapped(_ sender: UIButton) {
        if isRecognitionRunning {
            stopRecordingAndRecognition()
        } else {
            recordAndRecognizeSpeech()
        }
    }

    // MARK: Private helpers

    private func recordAndRecognizeSpeech() {
        debugPrint(#function)
        guard let node = audioEngine.inputNode else {
            return
        }
        isRecognitionRunning = true

        if audioEngine.isRunning {
            node.removeTap(onBus: audioBus)
        }

        let recordingFormat = node.outputFormat(forBus: audioBus)
        node.installTap(onBus: audioBus, bufferSize: bufferSize, format: recordingFormat) { [weak self] buffer, _ in
            self?.request.append(buffer)
        }

        // Prepare and start recording
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            isRecognitionRunning = false
            return debugPrint(error)
        }

        // Add timer for cancel recognition
        let timer = Timer(timeInterval: 5.0, target: self, selector: #selector(ViewController.timerEnded), userInfo: nil, repeats: false)
        RunLoop.current.add(timer, forMode: .commonModes)

        // Check recognizer
        guard let recognizer = SFSpeechRecognizer() else {
            // A recognizer is not supported for the current locale
            isRecognitionRunning = false
            return
        }
        if !recognizer.isAvailable {
            // A recognizer is not available right now
            isRecognitionRunning = false
            return
        }

        // Call the recognitionTask method on the recognizer and recognize speech
        recognitionTask = speechRecognizer?.recognitionTask(with: request, resultHandler: { [weak self] (result, error) in

            var isFinal = false

            if let result = result {
                let bestString = result.bestTranscription.formattedString
                self?.resultTextView.text = bestString

                isFinal = result.isFinal
            }
            if (error != nil) || isFinal {
                self?.stopRecordingAndRecognition()
            }
        })
    }

    private func stopRecordingAndRecognition() {
        debugPrint(#function)
        guard let node = audioEngine.inputNode else {
            return
        }

        // Remove tap cause only one tap may be installed on any bus
        if audioEngine.isRunning {
            node.removeTap(onBus: audioBus)
        }

        audioEngine.stop()
        recognitionTask = nil
        speechRecognizer = nil

        isRecognitionRunning = false
    }

}
