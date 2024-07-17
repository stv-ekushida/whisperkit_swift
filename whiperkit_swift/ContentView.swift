//
//  ContentView.swift
//  whiperkit_swift
//
//  Created by 串田栄二 on 2024/07/17.
//

import SwiftUI
import WhisperKit
import CoreML

struct ContentView: View {
    @State var whisperKit: WhisperKit? = nil
    @State private var localModelPath: String = ""
    @State private var localModels: [String] = []
    @State private var transcription = "音声をテキストに変換して表示します。"
    @State private var isTranscribing = false
    
    @AppStorage("repoName") private var repoName: String = "argmaxinc/whisperkit-coreml"
    @AppStorage("encoderComputeUnits") private var encoderComputeUnits: MLComputeUnits = .cpuAndNeuralEngine
    @AppStorage("decoderComputeUnits") private var decoderComputeUnits: MLComputeUnits = .cpuAndNeuralEngine
    
    var body: some View {
      VStack {
        Text(transcription)
              .padding()
          
        if isTranscribing {
          ProgressView("変換中...")
        } else {
          Button("音声ファイルを変換") {
            transcribeAudio()
          }
        }
      }
    }
    
    func transcribeAudio() {
      guard let audioURL = Bundle.main.url(forResource: "whisper_sample", withExtension: "mp3") else {
        transcription = "ファイルが見つかりません。"
        return
      }

      isTranscribing = true
      whisperKit = nil

      Task {
        do {
          //ModelVariant
          // base、largev3など
          let model = ModelVariant.base.description;
                                      
          whisperKit = try await WhisperKit(
            model: model,
            verbose: true,
            logLevel: .debug,
            prewarm: false,
            load: false,
            download: false
          )
                  
          guard let whisperKit = whisperKit else {
            return
          }
                  
          var folder: URL?
              
          if localModels.contains(model) {
            folder = URL(fileURLWithPath: localModelPath).appendingPathComponent(model)
          } else {
            folder = try await WhisperKit.download(variant: model, from: repoName)
          }
          
          guard let modelFolder = folder else {
            return
          }
          
          whisperKit.modelFolder = modelFolder
          
          // Prewarm models
          do {
            try await whisperKit.prewarmModels()
          } catch WhisperError.modelsUnavailable (let e){
            print(e);
            return
          }
          
          try await whisperKit.loadModels()
          
          await MainActor.run {
            if !localModels.contains(model) {
              localModels.append(model)
            }
          }
          
          guard whisperKit.tokenizer != nil else {
            throw WhisperError.tokenizerUnavailable()
          }
          
          //専門用語の学習
          let prompts = [
              "無添加しゃぼん玉石鹸ならもう安心",
              "お求めは0120-00-5595"
          ]
            
          var combinedTokens: [Int] = []
                              
          for promptText in prompts {
              if let tokens = whisperKit.tokenizer?.encode(text: promptText).filter({ $0 < (whisperKit.tokenizer?.specialTokens.specialTokenBegin ?? 0) }) {
                  combinedTokens.append(contentsOf: tokens)
              }
          }
                              
          transcription = "音声をテキストに変換して表示します。"
          
          let decodeOptions = DecodingOptions.init(
              language: "ja",
              skipSpecialTokens: true,
              promptTokens: combinedTokens
          )
          
          
          if let result = try await whisperKit.transcribe(
              audioPath: audioURL.path,
              decodeOptions: decodeOptions)?.text {
              transcription = result
          } else {
            transcription = "トランスクリプションを取得できませんでした。"
          }
      } catch {
        transcription = "エラーが発生しました: \(error)"
      }
          
      isTranscribing = false
    }
  }
}


#Preview {
    ContentView()
}
