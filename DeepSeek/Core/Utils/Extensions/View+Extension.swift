//
//  Date+Extension.swift
//  DeepSeek
//
//  Created by Harlans on 2024/12/1.
//

import SwiftUI

// MARK: - HideKeyboard View
extension View {
    func withHideKeyboard() -> some View {
        environment(\.hideKeyboard) {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                            to: nil,
                                            from: nil,
                                            for: nil)
        }
    }
}

// MARK: - Conditional View
extension View {
    /// Whether the view should be empty.
    /// - Parameter bool: Set to `true` to show the view (return EmptyView instead).
    func showIf(_ bool: Bool) -> some View {
        modifier(ConditionalView(show: [bool]))
    }
    
    /// returns a original view only if all conditions are true
    func showIf(_ conditions: Bool...) -> some View {
        modifier(ConditionalView(show: conditions))
    }
}

struct ConditionalView: ViewModifier {
    
    let show: [Bool]
    
    func body(content: Content) -> some View {
        Group {
            if show.filter({ $0 == false }).count == 0 {
                content
            } else {
                EmptyView()
            }
        }
    }
}


extension View {
    /// Usually you would pass  `@Environment(\.displayScale) var displayScale`
    @MainActor func render(scale displayScale: CGFloat = 1.0) -> PlatformImage? {
        let renderer = ImageRenderer(content: self)
        
        renderer.scale = displayScale
        
#if os(iOS) || os(visionOS)
        let image = renderer.uiImage
#elseif os(macOS)
        let image = renderer.nsImage
#endif
        
        return image
    }
}

extension View {
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    /// https://www.avanderlee.com/swiftui/conditional-view-modifier/
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct GradientForegroundStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.foregroundStyle(
            LinearGradient(
                colors: [Color(hex: "4285f4"), Color(hex: "9b72cb"), Color(hex: "d96570"), Color(hex: "#d96570")],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}

struct MovingGradientForegroundStyle: ViewModifier {
    @State private var animateGradient = false

    func body(content: Content) -> some View {
        content.overlay(
            LinearGradient(
                colors: [Color(hex: "4285f4"), Color(hex: "9b72cb")],
                startPoint: animateGradient ? .leading : .trailing,
                endPoint: animateGradient ? .trailing : .leading
            )
            .animation(Animation.linear(duration: 3).repeatForever(autoreverses: false), value: animateGradient)
        )
        .mask(content)
        .onAppear {
            animateGradient = true
        }
    }
}


extension View {
    func enchantify() -> some View {
        modifier(GradientForegroundStyle())
    }
    
    func enchantifyMoving() -> some View {
        self.modifier(MovingGradientForegroundStyle())
    }
}


extension View {
    /// Adds an underlying hidden button with a performing action that is triggered on pressed shortcut
    /// - Parameters:
    ///   - key: Key equivalents consist of a letter, punctuation, or function key that can be combined with an optional set of modifier keys to specify a keyboard shortcut.
    ///   - modifiers: A set of key modifiers that you can add to a gesture.
    ///   - perform: Action to perform when the shortcut is pressed
    public func onKeyboardShortcut(key: KeyEquivalent, modifiers: EventModifiers = .command, perform: @escaping () -> ()) -> some View {
        ZStack {
            Button("") {
                perform()
            }
            .hidden()
            .keyboardShortcut(key, modifiers: modifiers)
            
            self
        }
    }
}

