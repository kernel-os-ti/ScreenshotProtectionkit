import SwiftUI
//
//  ScreenCaptureOverlay.swift
//  StudioOnze
//
//  Created by Murilo Araujo on 11/08/24.
//  Copyright © 2024 br.com.studioonze. All rights reserved.
//
import UIKit

public enum ScreenCaptureEvent {
    case recording(Bool)
    case screenshot
}

@MainActor public protocol ScreenCaptureDetectable: ObservableObject {
    var isCaptured: Bool { get }
}

@MainActor public class ScreenCaptureManager: ScreenCaptureDetectable {
    @Published public var isCaptured: Bool = UIScreen.main.isCaptured

    private var captureObserver: NSObjectProtocol?

    public init() {
        captureObserver = NotificationCenter.default.addObserver(
            forName: UIScreen.capturedDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.isCaptured = UIScreen.main.isCaptured
            }
        }
    }

    @MainActor deinit {
        if let captureObserver = captureObserver {
            NotificationCenter.default.removeObserver(captureObserver)
        }
    }
}

public struct SecureUIView<Content: View>: UIViewRepresentable {

    let content: () -> Content

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    public func makeUIView(context: Context) -> UIView {

        let secureTextField = UITextField()
        secureTextField.isSecureTextEntry = true
        secureTextField.isUserInteractionEnabled = false

        guard let secureView = secureTextField.layer.sublayers?.first?.delegate as? UIView else {
            return UIView()
        }

        secureView.subviews.forEach { subview in
            subview.removeFromSuperview()
        }

        let hController = UIHostingController(rootView: content())
        hController.view.backgroundColor = .clear
        hController.view.translatesAutoresizingMaskIntoConstraints = false

        secureView.addSubview(hController.view)
        NSLayoutConstraint.activate([
            hController.view.topAnchor.constraint(equalTo: secureView.topAnchor),
            hController.view.bottomAnchor.constraint(equalTo: secureView.bottomAnchor),
            hController.view.leadingAnchor.constraint(equalTo: secureView.leadingAnchor),
            hController.view.trailingAnchor.constraint(equalTo: secureView.trailingAnchor),
        ])

        return secureView
    }

    public func updateUIView(_ uiView: UIView, context: Context) {}
}

public struct ScreenshotProtectedModifier<Placeholder: View>: ViewModifier {

    let placeholder: () -> Placeholder
    let onCapture: ((ScreenCaptureEvent) -> Void)?
    @StateObject private var captureManager = ScreenCaptureManager()

    public func body(content: Content) -> some View {
        Group {
            SecureUIView {
                content
            }
        }
        .overlay {
            if captureManager.isCaptured {
                CaptureWarningView()
            }
        }
        .onChange(of: captureManager.isCaptured) { newValue in
            onCapture?(.recording(newValue))
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)) { _ in
            onCapture?(.screenshot)
        }
    }
}

public struct DefaultScreenCapturePlaceholder: View {
    public init() {}

    public var body: some View {
        ZStack {
            Color.gray.opacity(0.3).blur(radius: 20)
            Text("Este conteúdo é protegido")
                .foregroundColor(.white)
                .bold()
        }
    }
}

extension View {

    /// Placeholder customizado e uma callback customizada para os eventos.
    public func screenshotProtected<Placeholder: View>(
        @ViewBuilder placeholder: @escaping () -> Placeholder,
        onCapture: ((ScreenCaptureEvent) -> Void)? = nil
    ) -> some View {
        self.modifier(ScreenshotProtectedModifier(placeholder: placeholder, onCapture: onCapture))
    }

    /// Placeholder customizado, com callback padrão que imprime o evento.
    public func screenshotProtected<Placeholder: View>(
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) -> some View {
        self.screenshotProtected(
            placeholder: placeholder,
            onCapture: { event in
                print("Evento de captura: \(event)")
            }
        )
    }

    /// Somente o callback customizado, com placeholder padrão.
    public func screenshotProtected(
        onCapture: @escaping (ScreenCaptureEvent) -> Void
    ) -> some View {
        self.screenshotProtected(placeholder: { DefaultScreenCapturePlaceholder() }, onCapture: onCapture)
    }

    /// Sem parâmetros, utilizando tanto o placeholder quanto o callback padrão.
    public func screenshotProtected() -> some View {
        self.screenshotProtected(
            placeholder: { DefaultScreenCapturePlaceholder() },
            onCapture: { event in
                print("Evento de captura: \(event)")
            }
        )
    }
}
