import Foundation

@MainActor
final class HTTPClient: LLMClient {
  struct Config {
    var endpoint: URL
    var apiKey: String
    var model: String
  }

  private let cfg: Config
  init(cfg: Config) { self.cfg = cfg }

  func complete(prompt: String, context: [String] = []) async throws -> String {
    var request = URLRequest(url: cfg.endpoint)
    request.httpMethod = "POST"
    request.setValue("Bearer \(cfg.apiKey)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body: [String: Any] = [
      "model": cfg.model,
      "messages": (context + [prompt]).map { ["role": "user", "content": $0] },
      "stream": false,
    ]
    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, _) = try await URLSession.shared.data(for: request)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    let content = ((json?["choices"] as? [[String: Any]])?.first?["message"] as? [String: String])?[
      "content"]
    return content ?? ""
  }
}
