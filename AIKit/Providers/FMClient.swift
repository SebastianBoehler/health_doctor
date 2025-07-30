import FoundationModels

@MainActor
final class FMClient: LLMClient {
  private lazy var session: LanguageModelSession = {
    precondition(
      SystemLanguageModel.default.isAvailable,
      "On-device model not present")
    return LanguageModelSession()
  }()

  func complete(prompt: String, context: [String] = []) async throws -> String {
    let fullPrompt = (context + [prompt]).joined(separator: "\n")
    return try await session.respond(to: fullPrompt).content
  }
}
