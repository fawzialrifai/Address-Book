//
//  ScannerCoordinator.swift
//  Address Book
//
//  Created by Fawzi Rifai on 14/05/2022.
//

import AVFoundation
import SwiftUI

extension CodeScannerView {
    public class ScannerCoordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: CodeScannerView
        var codesFound = Set<String>()
        var didFinishScanning = false

        init(parent: CodeScannerView) {
            self.parent = parent
        }

        public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            if let metadataObject = metadataObjects.first {
                guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
                guard let stringValue = readableObject.stringValue else { return }
                guard didFinishScanning == false else { return }
                if !codesFound.contains(stringValue) {
                    codesFound.insert(stringValue)
                    do {
                        guard let data = stringValue.data(using: .utf8) else { return }
                        found(data)
                        let _ = try JSONDecoder().decode(Contact.self, from: data)
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        didFinishScanning = true
                    } catch {
                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                    }
                }
            }
        }

        func found(_ data: Data) {
            parent.completion(.success(data))
        }

        func didFail(reason: ScanError) {
            parent.completion(.failure(reason))
        }
    }
}
