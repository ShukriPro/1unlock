//
//  MathView.swift
//  1unlock
//
//  Created by Shukri on 07/10/2025.
//


import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AVFoundation)
import AVFoundation
#endif

enum MathOperation {
    case multiply
    case add
    case subtract

    var symbol: String {
        switch self {
        case .multiply: return "×"
        case .add: return "+"
        case .subtract: return "−"
        }
    }
}

struct MathView: View {
    var questionType: MathOperation = .add
    var onUnlockApps: (() -> Void)? = nil
    @State private var leftOperand: Int = 8
    @State private var rightOperand: Int = 2
    @State private var options: [Int] = [16, 20, 12, 18]
    @State private var selectedAnswer: Int? = nil
    @State private var isAnswerCorrect: Bool? = nil
    @State private var correctCount: Int = 0
    @State private var wrongCount: Int = 0
    @State private var revealCorrect: Bool = false
    @State private var wrongSelection: Int? = nil
    @State private var isUnlocking: Bool = false
    @State private var isUnlocked: Bool = false
    @State private var unlockDots: Int = 0
    @State private var unlockTimer: Timer? = nil

    private var correctAnswer: Int {
        switch questionType {
        case .multiply: return leftOperand * rightOperand
        case .add: return leftOperand + rightOperand
        case .subtract: return leftOperand - rightOperand
        }
    }

    var body: some View {
        VStack(spacing: 40) {
            // Question
            VStack(spacing: 12) {
                Text("\(leftOperand) \(questionType.symbol) \(rightOperand)")
                    .font(.system(size: 48, weight: .bold))
                
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                        .font(.system(size: 12))
                    Text("\(correctCount)")
                        .foregroundColor(.green)
                        .font(.system(size: 14))
                    Image(systemName: "xmark")
                        .foregroundColor(.red)
                        .font(.system(size: 12))
                    Text("\(wrongCount)")
                        .foregroundColor(.red)
                        .font(.system(size: 14))
                }
            }
            .padding(.top, 100)
            
            // Answers
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    AnswerBox(
                        number: options[safe: 0] ?? 0,
                        isSelected: selectedAnswer == (options[safe: 0] ?? -1),
                        selectionResult: (selectedAnswer == (options[safe: 0] ?? -1)) ? isAnswerCorrect : nil,
                        forceCorrect: revealCorrect && ((options[safe: 0] ?? Int.min) == correctAnswer),
                        forceWrong: (wrongSelection != nil) && ((options[safe: 0] ?? Int.min) == wrongSelection),
                        isDisabled: isAnswerCorrect == true,
                        action: { selectAnswer(options[safe: 0] ?? 0) }
                    )
                    AnswerBox(
                        number: options[safe: 1] ?? 0,
                        isSelected: selectedAnswer == (options[safe: 1] ?? -1),
                        selectionResult: (selectedAnswer == (options[safe: 1] ?? -1)) ? isAnswerCorrect : nil,
                        forceCorrect: revealCorrect && ((options[safe: 1] ?? Int.min) == correctAnswer),
                        forceWrong: (wrongSelection != nil) && ((options[safe: 1] ?? Int.min) == wrongSelection),
                        isDisabled: isAnswerCorrect == true,
                        action: { selectAnswer(options[safe: 1] ?? 0) }
                    )
                }
                HStack(spacing: 16) {
                    AnswerBox(
                        number: options[safe: 2] ?? 0,
                        isSelected: selectedAnswer == (options[safe: 2] ?? -1),
                        selectionResult: (selectedAnswer == (options[safe: 2] ?? -1)) ? isAnswerCorrect : nil,
                        forceCorrect: revealCorrect && ((options[safe: 2] ?? Int.min) == correctAnswer),
                        forceWrong: (wrongSelection != nil) && ((options[safe: 2] ?? Int.min) == wrongSelection),
                        isDisabled: isAnswerCorrect == true,
                        action: { selectAnswer(options[safe: 2] ?? 0) }
                    )
                    AnswerBox(
                        number: options[safe: 3] ?? 0,
                        isSelected: selectedAnswer == (options[safe: 3] ?? -1),
                        selectionResult: (selectedAnswer == (options[safe: 3] ?? -1)) ? isAnswerCorrect : nil,
                        forceCorrect: revealCorrect && ((options[safe: 3] ?? Int.min) == correctAnswer),
                        forceWrong: (wrongSelection != nil) && ((options[safe: 3] ?? Int.min) == wrongSelection),
                        isDisabled: isAnswerCorrect == true,
                        action: { selectAnswer(options[safe: 3] ?? 0) }
                    )
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(screenBackground)
        .onAppear { nextQuestion() }
        .safeAreaInset(edge: .bottom) {
            let unlockEnabled = correctCount >= 5
            let canTap = unlockEnabled && !isUnlocking && !isUnlocked
            let buttonText: String = {
                if isUnlocked { return "Apps Unlocked" }
                if isUnlocking { return "Unlocking" + String(repeating: ".", count: (unlockDots % 3) + 1) }
                return "Unlock Apps"
            }()
            let fgColor: Color = isUnlocked ? .white : (canTap ? .white : .white.opacity(0.6))
            let bgColor: Color = isUnlocked ? .green : (canTap ? Color.accentColor : Color.accentColor.opacity(0.5))

            Button(action: { if canTap { startUnlockFlow() } }) {
                Text(buttonText)
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .foregroundColor(fgColor)
            .background(bgColor)
            .cornerRadius(14)
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .disabled(!canTap)
        }
    }

    private var screenBackground: Color {
        #if canImport(UIKit)
        return Color(UIColor.systemBackground)
        #else
        return Color.white
        #endif
    }

    private func nextQuestion() {
        // Generate a new question
        var a = Int.random(in: 2...12)
        var b = Int.random(in: 2...12)
        if questionType == .subtract, a < b {
            swap(&a, &b) // avoid negative results for subtraction
        }
        leftOperand = a
        rightOperand = b
        let correct = correctAnswer

        // Generate 3 unique distractors around the correct answer
        var set = Set<Int>()
        set.insert(correct)
        var generated: [Int] = [correct]

        while generated.count < 4 {
            let offset = Int.random(in: -6...6)
            var candidate = correct + offset
            if candidate == correct { candidate += Int.random(in: 1...3) }
            candidate = max(0, candidate)
            if !set.contains(candidate) {
                set.insert(candidate)
                generated.append(candidate)
            }
        }
        options = generated.shuffled()
        selectedAnswer = nil
        isAnswerCorrect = nil
        revealCorrect = false
        wrongSelection = nil
    }

    private func selectAnswer(_ value: Int) {
        // If already answered correctly, ignore further taps
        if isAnswerCorrect == true { return }

        selectedAnswer = value
        if value == correctAnswer {
            isAnswerCorrect = true
            correctCount += 1
            playFeedback(success: true)
            // Proceed to next question after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                nextQuestion()
            }
        } else {
            // Wrong attempt: reveal correct answer and keep wrong highlighted, do not advance
            isAnswerCorrect = nil
            wrongCount += 1
            wrongSelection = value
            revealCorrect = true
            playFeedback(success: false)
        }
    }

    private func startUnlockFlow() {
        isUnlocking = true
        unlockDots = 0
        unlockTimer?.invalidate()
        unlockTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
            unlockDots = (unlockDots + 1) % 3
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            onUnlockApps?()
            unlockTimer?.invalidate()
            unlockTimer = nil
            isUnlocking = false
            isUnlocked = true
        }
    }

    private func playFeedback(success: Bool) {
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(success ? .success : .error)
        #endif
        #if canImport(AVFoundation)
        if success {
            SoundManager.shared.playCorrect()
        } else {
            SoundManager.shared.playWrong()
        }
        #endif
    }
}

struct AnswerBox: View {
    let number: Int
    let isSelected: Bool
    let selectionResult: Bool?
    let forceCorrect: Bool
    let forceWrong: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("\(number)")
                .font(.system(size: 32, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 100)
        }
        .background(backgroundColor)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: isSelected ? 2 : 0)
        )
        .animation(.easeInOut(duration: 0.2), value: selectionResult)
        .animation(.easeInOut(duration: 0.2), value: forceCorrect)
        .animation(.easeInOut(duration: 0.2), value: forceWrong)
        .disabled(isDisabled)
    }

    private var backgroundColor: Color {
        if forceCorrect { return Color.green.opacity(0.25) }
        if forceWrong { return Color.red.opacity(0.25) }
        if isSelected, let selectionResult {
            return selectionResult ? Color.green.opacity(0.25) : Color.red.opacity(0.25)
        }
        return platformSecondaryBackground
    }

    private var borderColor: Color {
        if forceCorrect { return .green }
        if forceWrong { return .red }
        if isSelected, let selectionResult {
            return selectionResult ? .green : .red
        }
        return .clear
    }

    private var platformSecondaryBackground: Color {
        #if canImport(UIKit)
        return Color(UIColor.secondarySystemBackground)
        #else
        return Color.gray.opacity(0.2)
        #endif
    }
}

// Safe index access utility
private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}

#if canImport(AVFoundation)
final class SoundManager {
    static let shared = SoundManager()

    private var correctPlayer: AVAudioPlayer?
    private var wrongPlayer: AVAudioPlayer?

    private init() {
        // Try to load optional sound assets if present in bundle
        if let url = Bundle.main.url(forResource: "correct", withExtension: "wav") ??
                     Bundle.main.url(forResource: "correct", withExtension: "mp3") {
            correctPlayer = try? AVAudioPlayer(contentsOf: url)
            correctPlayer?.prepareToPlay()
        }
        if let url = Bundle.main.url(forResource: "wrong", withExtension: "wav") ??
                     Bundle.main.url(forResource: "wrong", withExtension: "mp3") {
            wrongPlayer = try? AVAudioPlayer(contentsOf: url)
            wrongPlayer?.prepareToPlay()
        }
    }

    func playCorrect() {
        correctPlayer?.play()
    }

    func playWrong() {
        wrongPlayer?.play()
    }
}
#endif

#Preview {
    MathView()
}
