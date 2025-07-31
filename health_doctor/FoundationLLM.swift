//  FoundationLLM.swift
//  health_doctor
//
//  Created by Cascade AI on 31.07.25.
//  A thin wrapper around Apples FoundationModels framework to provide an easy
//  async interface for generating text with the on device LLM.

import Foundation

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 18.0, macOS 15.0, *)
actor FoundationLLM {
    /// Convenience static wrapper so callers can use `FoundationLLM.generate(prompt:)` uniformly
    static func generate(prompt: String) async throws -> String {
        try await shared.generate(prompt: prompt)
    }
    static let shared = FoundationLLM()

    private let session: LanguageModelSession

    init() {
        // Use the default ondevice system language model (general use case).
        let model = SystemLanguageModel(useCase: .general)
        self.session = LanguageModelSession(model: model)
    }

    /// Generate a single text completion for the given prompt.
    /// - Parameter prompt: The user prompt.
    /// - Returns: Model response as `String`.
    func generate(prompt: String) async throws -> String {
        let response = try await session.respond(to: prompt)
        return response.content
    }
}
#else
// Fallback stub so the project still compiles on older OS versions/SDKs.
struct FoundationLLM {
    static func generate(prompt _: String) async throws -> String {
        throw NSError(domain: "FoundationLLM", code: -1,
                      userInfo: [NSLocalizedDescriptionKey: "FoundationModels framework is not available on this platform."])
    }
}
#endif
