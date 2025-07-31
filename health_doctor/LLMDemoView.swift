//  LLMDemoView.swift
//  health_doctor
//
//  Created by Cascade AI on 31.07.25.
//  A minimal SwiftUI view to test Apple FoundationModels integration.

import SwiftUI

struct LLMDemoView: View {
    @State private var prompt: String = ""
    @State private var output: String = ""
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        Group {
#if canImport(FoundationModels)
            if #available(iOS 18.0, macOS 15.0, *) {
                switch SystemLanguageModel.default.availability {
                case .available:
                    chatUI
                case .unavailable(let reason):
                    Text(unavailableMessage(for: reason))
                @unknown default:
                    Text("The language model is unavailable for an unknown reason.")
                }
            } else {
                Text("FoundationModels requires iOS 18/macOS 15 or later.")
            }
#else
            Text("FoundationModels framework is not available on this platform.")
#endif
        }
    }

    // MARK: - Chat UI
#if canImport(FoundationModels)
    @available(iOS 18.0, macOS 15.0, *)
    private var chatUI: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Foundation LLM Demo")
                .font(.title2)
                .bold()

            TextField("Enter prompt", text: $prompt, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3, reservesSpace: true)

            HStack {
                Spacer()
                Button(action: generate) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Run")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            }

            Divider()

            ScrollView {
                if let error {
                    Text(error)
                        .foregroundColor(.red)
                } else {
                    Text(output.isEmpty ? "Model output will appear here" : output)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding()
    }
#endif
    // MARK: - Helpers
#if canImport(FoundationModels)
    @available(iOS 18.0, macOS 15.0, *)
    private func unavailableMessage(for reason: SystemLanguageModel.UnavailabilityReason) -> String {
        switch reason {
        case .appleIntelligenceNotEnabled:
            return "Apple Intelligence is not enabled. Please enable it in Settings."
        case .deviceNotEligible:
            return "This device is not eligible for Apple Intelligence. Please use a compatible device."
        case .modelNotReady:
            return "The language model is not ready yet. Please try again later."
        @unknown default:
            return "The language model is unavailable for an unknown reason."
        }
    }
#endif

    private func generate() {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        output = ""
        error = nil
        isLoading = true

        Task {
            do {
                if #available(iOS 18.0, macOS 15.0, *) {
                    let response = try await FoundationLLM.generate(prompt: prompt)
                    await MainActor.run {
                        output = response
                        isLoading = false
                    }
                } else {
                    await MainActor.run {
                        error = "FoundationModels framework requires iOS 18/macOS 15 or later."
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    LLMDemoView()
}
