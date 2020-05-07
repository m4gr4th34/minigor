//
//  Additional_functions.swift
//  Test New
//
//  Created by Ali Smooth on 8/6/19.
//  Copyright © 2019 Irfan Ali Khan. All rights reserved.
//

import Foundation
import NaturalLanguage


let MASTER_version = "04"


private func loadQuotes(field:Int) -> Dictionary<String, String>{
    print("loading quotes ... ")
    guard let path = Bundle.main.path(forResource: "XCODE_The_quotes_master_" + MASTER_version, ofType: "json") else { return [:]}
    do {
        let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
        let jsonResult = try JSONSerialization.jsonObject(with: data)
        var quote_tracker = Dictionary<String, String>()
        if let jsonResult = jsonResult as? Dictionary<String, AnyObject>, let quotes = jsonResult["quotes"] as? [NSDictionary] {
            for quote in quotes {
                quote_tracker[quote["quoteLemmas"] as! String] = (quote["quoteText"] as! String)
            }
            return quote_tracker
        }
    } catch {
        print("error loading quotes")
        return [:]
    }
    return [:]
}


let quote_tracker = loadQuotes(field: 0)
let lemmer = NLTagger(tagSchemes: [.lemma])


func tf(urlString: String,
        word: String,
        wordCountings: Dictionary<String, Dictionary<String, Int>>,
        totalWordCount: Int)
    -> Double {
        guard let wordCounting = wordCountings[word] else {
            return Double(Int.min)
        }
        guard let occurrences = wordCounting[urlString] else {
            return Double(Int.min)
        }
        return Double(occurrences) / Double(totalWordCount)
}


func idf(urlString: String,
         word: String,
         wordCountings: Dictionary<String, Dictionary<String, Int>>,
         totalDocs: Int)
    -> Double {
        guard let wordCounting = wordCountings[word] else {
            return 1
        }
        var sum = 0
        for (url, count) in wordCounting {
            if url != urlString {
                sum += count
            }
        }
        if sum == 0 {
            return 1
        }
        let factor = Double(totalDocs) / Double(sum)
        return log(factor)
}


func tfIdf(urlString: String,
           word: String,
           wordCountings: Dictionary<String, Dictionary<String, Int>>,
           totalWordCount: Int,
           totalDocs: Int)
    -> Double {
        return tf(urlString: urlString,
                  word: word,
                  wordCountings: wordCountings,
                  totalWordCount: totalWordCount)
            * idf(urlString: urlString,
                  word: word, wordCountings: wordCountings,
                  totalDocs: totalDocs)
}


func makeDictionary() -> (Dictionary<String, Dictionary<String, Int>>) { //// I load pre-made dictionary to save big(O)
    print("making dictionary ... ")
    guard let path = Bundle.main.path(forResource: "XCODE_The_dictionary_master_" + MASTER_version, ofType: "json") else { print("file issue"); return [:]}
    do {
        let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
        let jsonResult = try JSONSerialization.jsonObject(with: data)
        print("starting to load ... ")
        var word_countings1 = Dictionary<String, Dictionary<String, Int>>()
        print("still loading ... ")
        if let jsonResult = jsonResult as? Dictionary<String, Any>, let lemmas = jsonResult["lemmas"] as? Dictionary<String, Dictionary<String, Int>> {
            print( "loaded successfully ... " )
            print(lemmas.count)
            word_countings1 = (lemmas as? Dictionary<String, Dictionary<String, Int>>)!
        }
        return ( word_countings1 )
    } catch {
        print("error loading dictionary")
        return [:]
    }
}


func readSavedState() -> (Dictionary<String, Int>) {
    print("reading saved state ... ")
    let pathDirectory = getLoadDocumentsDirectory()
    try? FileManager().createDirectory(at: pathDirectory, withIntermediateDirectories: true)
    let filepath = pathDirectory.appendingPathComponent("save_state.json")
    let path: String = filepath.path
    print(path)
    do {
        //print("0")
        let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
        //print("1")
        let jsonResult = try JSONSerialization.jsonObject(with: data)
        print("starting to load saves ... ")
        var word_countings1 = Dictionary<String, Int>()
        //print("still loading saves ... ")
        if let jsonResult = jsonResult as? Dictionary<String, Any>, let voice = jsonResult["voice_used"] as? Int {
            //print( "loaded saves successfully ... " )
            word_countings1["voice_used"] = voice
        }
        if let jsonResult = jsonResult as? Dictionary<String, Any>, let font_size = jsonResult["font_size"] as? Int {
            print( "loaded saves successfully ... " )
            word_countings1["font_size"] = font_size
        }
        return ( word_countings1 )
    } catch {
        print("error loading save state")
        return [ "font_size": 18, "voice_used": -2 ]
    }
}


func getLoadDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}


var word_countings = makeDictionary()
var the_saved_values = readSavedState()
//let voices = AVSpeechSynthesisVoice.speechVoices()
var select_voice = -1
