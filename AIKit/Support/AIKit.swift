import Foundation

@MainActor
public enum AIBackend {
  case foundation
  case openAI(apiKey: String, model: String)
}

@MainActor
public struct AIKit {
  public static func client(for backend: AIBackend) -> LLMClient {
    switch backend {
    case .foundation:
      return FMClient()
    case let .openAI(key, model):
      let cfg = HTTPClient.Config(
        endpoint: URL(string: "https://api.openai.com/v1/chat/completions")!,
        apiKey: key,
        model: model
      )
      return HTTPClient(cfg: cfg)
    }
  }
}
