//
//  ViewController.swift
//  Test New
//
//  Created by Ali Smooth on 7/23/19.
//  Copyright © 2019 Irfan Ali Khan. All rights reserved.
//

import UIKit
import Foundation
import NaturalLanguage
import AVFoundation
import Speech




class ViewController: UIViewController, SFSpeechRecognizerDelegate, UIPickerViewDelegate, UIPickerViewDataSource {

    
    
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return arrVoiceLanguages.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        let voiceLanguagesDictionary = arrVoiceLanguages[row] as Dictionary<String, String?>
        return voiceLanguagesDictionary["languageName"]!
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedVoiceLanguage = row
        select_voice = selectedVoiceLanguage
        self.currentVoice.text = arrVoiceLanguages[row]["languageName"]
        igorOutput.text = "\n \nyou can add even more voices by going to: \n \n     ios settings \n          ->general \n               ->accessability \n                    ->speech \n \nand installing them onto your iOS.  (requires app restart to use, Siri voice not available.)"
        self.voicepicker.isHidden = true
        the_saved_values["voice_used"] = row
        saveJasonFile()
        yourInput.becomeFirstResponder()
        currentVoice.resignFirstResponder()
    }

    
    @IBOutlet weak var currentVoice: UITextField!
    @IBOutlet weak var yourInput: UITextField!
    @IBOutlet weak var igorOutput: UITextView!
    @IBOutlet weak var igorThinking: UIActivityIndicatorView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var StepperVal: UIStepper!
    @IBOutlet weak var voicepicker: UIPickerView!
    
    
    var audioSession = AVAudioSession.sharedInstance()
    let audioEngine = AVAudioEngine()
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    var isRecording = false
    var fromspeech = ""
    var arrVoiceLanguages: [Dictionary<String, String>] = []
    var selectedVoiceLanguage = 0
    let voices = AVSpeechSynthesisVoice.speechVoices()
    var reroll = "nothing"
    let avSpeechSynthesizer = AVSpeechSynthesizer()
    
    func prepareVoiceList() {
        let all_voices = AVSpeechSynthesisVoice.speechVoices()
        for i in (0 ... all_voices.count-1){
            let voiceLanguageCode = String(i)
            let voice_lang = (all_voices[i] as AVSpeechSynthesisVoice).language
            let voice_name = (all_voices[i] as AVSpeechSynthesisVoice).name
            let languageName = voice_lang + ": " + voice_name
            let dictionary = ["languageName": languageName, "languageCode": voiceLanguageCode]
            arrVoiceLanguages.append(dictionary)
        }
    }
    
    
    func loadSavedState(){
        let xx:Int = the_saved_values["font_size"] ?? 11
        igorOutput.font = UIFont(name: "Arial", size: CGFloat(xx))
        StepperVal.value = Double(xx)
        select_voice = the_saved_values["voice_used"] ?? -4
    }
    
    
 ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ////  Do any additional setup after loading the view.
        startButton.layer.cornerRadius = 20
        yourInput.delegate = self
        prepareVoiceList()
        loadSavedState()
        makeDictionary()
    }
    
    
    
    
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    
    @IBAction func VoiceStepper(_ sender: UIStepper) { ////  actually it is a font stepper, so sorry for confusion, need to rename in next version.
        igorOutput.font = UIFont(name: "Arial", size: CGFloat(Int(sender.value)))
        igorOutput.text = "Font size: " + String(Int(sender.value)) //
        the_saved_values["font_size"] = Int(sender.value)
        saveJasonFile()
    }
    
    
    @IBAction func LiveSpeechButton(_ sender: UIButton) {
        if isRecording == true {
            self.audioEngine.stop()
            self.recognitionTask?.cancel()
            self.isRecording = false
            self.cancelRecording()
            let temp_transfer = self.yourInput.text!
            //reroll = temp_transfer
            let color_disable = self.hexStringToUIColor(hex: "#8c8b89")
            startButton.backgroundColor = color_disable
            self.startButton.setTitle("Thinking...", for: .normal)
            startButton.isEnabled = false
            yourInput.text = "\n"
            igorOutput.text = temp_transfer
            igorThinking.startAnimating()
            //// Switch to background thread to perform heavy task.
            DispatchQueue.global(qos: .userInteractive).async {
                //// Perform heavy task here.
                let the_output = self.igorResponse(input: temp_transfer)
                ////  Switch back to main thread to perform UI-related task.
                DispatchQueue.main.async {
                    ////  Update UI.
                    let color_off = self.hexStringToUIColor(hex: "#5f8ad5")
                    self.startButton.backgroundColor = color_off
                    self.igorOutput.text = the_output //self.cleanQuote(the_output)
                    self.speakThis(self.toreadQuote(the_output))
                    self.igorThinking.stopAnimating()
                    self.startButton.isEnabled = true
                    self.startButton.setTitle("Record", for: .normal)
                }
            }
        } else {
            self.recordAndRecognizeSpeech()
            isRecording = true
            let color_on = hexStringToUIColor(hex: "#fc32d2")
            startButton.backgroundColor = color_on
            startButton.setTitle("Stop", for: .normal)
        }
    }
    
    
    func saveJasonFile(){
        print("saving json save file ... ")
        let pathDirectory = getDocumentsDirectory()
        try? FileManager().createDirectory(at: pathDirectory, withIntermediateDirectories: true)
        let filePath = pathDirectory.appendingPathComponent("save_state.json")
        print(filePath)
        //bookmarkDataWithOptions:includingResourceValuesForKeys:relativeToURL:error:
        let json = try? JSONEncoder().encode(the_saved_values)
        do {
            try json!.write(to: filePath)
            print("save success")
            print(the_saved_values)
        } catch {
            print("Failed to write JSON data: \(error.localizedDescription)")
        }
    }
    
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    

    func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        if ((cString.count) != 6) {
            return UIColor.gray
        }
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }

    
    func recordAndRecognizeSpeech() { //// recognize speech
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.record)
            //try audioSession.setMode(AVAudioSession.Mode.measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.request.append(buffer)
        }
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            //self.sendAlert(message: "There has been an audio engine error.")
            return print(error)
        }
        guard let myRecognizer = SFSpeechRecognizer() else {
            //self.sendAlert(message: "Speech recognition is not supported for your current locale.")
            return
        }
        if !myRecognizer.isAvailable {
            //self.sendAlert(message: "Speech recognition is not currently available. Check back at a later time.")
            // Recognizer is not available right now
            return
        }
        recognitionTask = speechRecognizer?.recognitionTask(with: request, resultHandler: { result, error in
            if let result = result {
                
                let bestString = result.bestTranscription.formattedString
                //self.LiveSpeechPreview.text = bestString
                self.yourInput.text = bestString
                self.fromspeech = bestString
            } else if let error = error {
                print(error)
            }
        })
    }
    
    
    func cancelRecording() {
        audioEngine.stop()
        let node = audioEngine.inputNode
        node.removeTap(onBus: 0)
        recognitionTask?.cancel()
    }

    
    func igorResponse(input: String) -> String {
        //// to lemmatize the user input to use when performing tfidf below
        avSpeechSynthesizer.stopSpeaking(at: .immediate)
        var user_input = input
        print(input)
        if input == " " || input == "" { //// if you press enter without input, it re-asks the previous question
            user_input = reroll
        }
        reroll = user_input
        print(user_input)
        //let user_input = input
        var u_build_str = ""
        var u_words:Array<String> = [String]()
        lemmer.string = user_input
        let _: NLTagger.Options = [.omitWhitespace, .omitPunctuation]
        let strRange = user_input.startIndex ..< user_input.endIndex
        lemmer.enumerateTags(in: strRange, unit: .word, scheme: .lemma) { (tag, tagRange) in if let lemma = tag?.rawValue {
            u_build_str = u_build_str + lemma + " "
            u_words.append(lemma)
            }
            return true
        }
        var result_tracker = Dictionary<String, Double>()
        for a_lemma in u_words { ////not cosine similarity, but works well, and is efficient.
            var result:Double = 0
            if word_countings[a_lemma] != nil{
                let word_counting = word_countings[a_lemma]
                for phrase in word_counting!{
                    let q_size = ((phrase.key.components(separatedBy: .whitespacesAndNewlines)).filter { !$0.isEmpty }).count
                    result = (tfIdf(urlString: phrase.key as! String, word: a_lemma, wordCountings: word_countings, totalWordCount: q_size as! Int, totalDocs: quote_tracker.count) / 10e+18)
                    if result_tracker[phrase.key] == nil {
                        result_tracker[phrase.key] = 0
                    result_tracker[phrase.key] = result_tracker[phrase.key]! + result
                    }
                }
            }
        }
        ////  i've populated result_tracker with non-zero tfidf results.  since deeply lemmerized, expect not too many items here.
        ////  result_tracker.key = lemmatized quote string
        ////  result_tracker.value = tfidf double value (total calculation)
        ////  the below code is to inverse the result_tracker dictionary, so that i can point tfidf value to lemmatized quote, and a step below to a full quote.
        var quote_as_tfidf = [Double]()
        var inverse = Dictionary<Double, String>()
        var track2:Double = 0
        let fixit = 0.000000001 ////  used to expand dictionary of answer pool, in case of identical tfidfs
        for phrase in result_tracker{
            if inverse[phrase.value] == nil{ ////  if tfidf value not already used.
                inverse[phrase.value] = quote_tracker[phrase.key]
                quote_as_tfidf.append(phrase.value)
            } else { ////  if tfidf value already used, create a unique value (revisit with loop, to ensure capture all)
                inverse[phrase.value + (track2*fixit)] = quote_tracker[phrase.key]
                quote_as_tfidf.append(phrase.value + (track2*fixit))
            }
            track2 += 1
        }
        var sort_it = quote_as_tfidf
        sort_it.sort()
        sort_it.reverse()
        let answer_pool = min(200, inverse.count - 1) ////  defines the sampe size for top random answers
        var the_output = "sorry, i didn't understand!"
        if answer_pool > 0 {
            let number_r = Int.random(in: 0 ... answer_pool)
            the_output = inverse[sort_it[number_r]]!
        }
        return the_output
    }
    
    
    func toreadQuote(_ in_text: String) -> String {
        var to_clean = NSMutableString(string: in_text)
        var regex = try? NSRegularExpression(pattern: "\n--.*") //// removing author name from read output
        regex?.replaceMatches(in: to_clean , options: .reportProgress, range: NSRange(location: 0,length: to_clean.length), withTemplate: " ")
        regex = try? NSRegularExpression(pattern: "\\.")
        regex?.replaceMatches(in: to_clean , options: .reportProgress, range: NSRange(location: 0,length: to_clean.length), withTemplate: ",")// . ,") // ,")
        regex = try? NSRegularExpression(pattern: "\\?")
        regex?.replaceMatches(in: to_clean , options: .reportProgress, range: NSRange(location: 0,length: to_clean.length), withTemplate: "? ,")
        regex = try? NSRegularExpression(pattern: "\\!")
        regex?.replaceMatches(in: to_clean , options: .reportProgress, range: NSRange(location: 0,length: to_clean.length), withTemplate: "! ,")
        regex = try? NSRegularExpression(pattern: "--unknown--")
        regex?.replaceMatches(in: to_clean , options: .reportProgress, range: NSRange(location: 0,length: to_clean.length), withTemplate: " ")
        return to_clean as String
    }
    
    
    func cleanQuote(_ in_text: String) -> String {
        var to_clean = NSMutableString(string: in_text)
        var regex = try? NSRegularExpression(pattern: ". ,")
        regex?.replaceMatches(in: to_clean , options: .reportProgress, range: NSRange(location: 0,length: to_clean.length), withTemplate: ".")
        regex = try? NSRegularExpression(pattern: " {1}[.]")
        regex?.replaceMatches(in: to_clean , options: .reportProgress, range: NSRange(location: 0,length: to_clean.length), withTemplate: ".")
        return to_clean as String
    }

    
    func speakThis(_ to_say: String) {
        ////  --- AVSpeechUtterance:
        do
        {
            try audioSession.setCategory(AVAudioSession.Category.playback)
            //try audioSession.setMode(AVAudioSession.Mode.default)
            //try audioSession.setMode(AVAudioSession.Mode.measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            try audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
        }
        catch
        {
            print("audioSession properties weren't set because of an error.")
        }
        //let avSpeechSynthesizer = AVSpeechSynthesizer()
        let utterance = AVSpeechUtterance(string: to_say)
        if select_voice < 0{
            utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
        }
        else{
            utterance.voice = voices[select_voice]
        }
        utterance.volume = 1
        utterance.rate = 0.4//0.33
        avSpeechSynthesizer.speak(utterance) ////  Start speech
        //do { try audioSession.setActive(false) }
        //catch { print("audioSession didn't close because of an error.") }
        //audioEngine.inputNode.removeTap(onBus: 0)
        //audioEngine.stop()
        //cancelRecording()
    }
    
    
    
    
}




extension ViewController : UITextFieldDelegate {
    
    
    
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if (textField == self.currentVoice){
            self.igorOutput.text = "\n"
            self.voicepicker.isHidden = false
        }
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField == self.yourInput){
            let temp_transfer = yourInput.text!
            let color_disable = self.hexStringToUIColor(hex: "#8c8b89")
            startButton.backgroundColor = color_disable
            self.startButton.setTitle("Thinking...", for: .normal)
            startButton.isEnabled = false
            yourInput.text = "\n"
            igorOutput.text = temp_transfer
            igorThinking.startAnimating()
            ////  Switch to background thread to perform heavy task.
            DispatchQueue.global(qos: .userInteractive).async {
                ////  Perform heavy task here.
                let the_output = self.igorResponse(input: temp_transfer)
                ////  Switch back to main thread to perform UI-related task.
                DispatchQueue.main.async {
                    ////  Update UI.
                    let color_off = self.hexStringToUIColor(hex: "#5f8ad5")
                    self.startButton.backgroundColor = color_off
                    self.igorOutput.text = the_output
                    self.speakThis(self.toreadQuote(the_output))
                    self.igorThinking.stopAnimating()
                    self.startButton.isEnabled = true
                    self.startButton.setTitle("Record", for: .normal)
                }
            }
        }
        return true
    }
    
    
    
    
}
