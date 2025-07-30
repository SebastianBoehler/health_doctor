import Foundation

@MainActor
public protocol LLMClient {
  func complete(prompt: String, context: [String]) async throws -> String
}
