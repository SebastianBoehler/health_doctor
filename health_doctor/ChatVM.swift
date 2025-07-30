import Foundation
import SwiftUI

@MainActor
final class ChatVM: ObservableObject {
  @Published var transcript: [String] = []
  private let llm: LLMClient

  init(backend: AIBackend = .foundation) {
    llm = AIKit.client(for: backend)
  }

  func send(_ text: String) async {
    do {
      let reply = try await llm.complete(prompt: text, context: transcript)
      transcript.append(contentsOf: [text, reply])
    } catch {
      transcript.append("Error: \(error.localizedDescription)")
    }
  }
}
