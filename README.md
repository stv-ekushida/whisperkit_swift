# WhisperKitデモ


## 専門用語の学習

```
  //専門用語の登録
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

  let decodeOptions = DecodingOptions.init(
    language: "ja",
    skipSpecialTokens: true,
    promptTokens: combinedTokens
  )
```
