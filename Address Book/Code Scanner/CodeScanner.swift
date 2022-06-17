//
//  CodeScanner.swift
//  Address Book
//
//  Created by Fawzi Rifai on 14/05/2022.
//

import AVFoundation
import SwiftUI

public enum ScanError: Error {
    case badInput
    case badOutput
    case initError(_ error: Error)
}



/// A SwiftUI view that is able to scan barcodes, QR codes, and more, and send back what was found.
/// To use, set `completion` to a closure that will be called when scanning has finished
/// This will be sent the data that was detected or a `ScanError`.
/// For testing inside the simulator, set the `simulatedData` property to some test data you want to send back.
public struct CodeScannerView: UIViewControllerRepresentable {
    
    public var simulatedData = ""
    public var isTorchOn: Bool
    public var isGalleryPresented: Binding<Bool>
    public var videoCaptureDevice: AVCaptureDevice?
    public var completion: (Result<Data?, ScanError>) -> Void

    public init(
        simulatedData: String = "",
        isTorchOn: Bool = false,
        isGalleryPresented: Binding<Bool> = .constant(false),
        videoCaptureDevice: AVCaptureDevice? = AVCaptureDevice.default(for: .video),
        completion: @escaping (Result<Data?, ScanError>) -> Void
    ) {
        self.simulatedData = simulatedData
        self.isTorchOn = isTorchOn
        self.isGalleryPresented = isGalleryPresented
        self.videoCaptureDevice = videoCaptureDevice
        self.completion = completion
    }

    public func makeCoordinator() -> ScannerCoordinator {
        ScannerCoordinator(parent: self)
    }

    public func makeUIViewController(context: Context) -> ScannerViewController {
        let viewController = ScannerViewController()
        viewController.delegate = context.coordinator
        return viewController
    }

    public func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {
        uiViewController.updateViewController(
            isTorchOn: isTorchOn,
            isGalleryPresented: isGalleryPresented.wrappedValue
        )
    }
    
}

struct CodeScannerView_Previews: PreviewProvider {
    static var previews: some View {
        CodeScannerView() { result in
            // do nothing
        }
    }
}
