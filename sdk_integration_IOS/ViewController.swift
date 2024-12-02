import UIKit
import Foundation
import VIDVOCR

class ViewController: UIViewController, VIDVOCRDelegate, VIDVLogsDelegate {
    var vidvOcrBuilder = OCRBuilder() // Initialize OCR builder

    override func viewDidLoad() {
        super.viewDidLoad()
        configureOCR() // Configure the OCR builder
    }

    private func configureOCR() {
        vidvOcrBuilder = vidvOcrBuilder
            .setBundleKey("2b92d93b823142899e70eede53182735")
            .setBaseUrl("https://valifystage.com/api/")
            .setAccessToken("<ACCESS_TOKEN>") // Replace with valid token at runtime
            .setLogsDelegate(self) // Enable logging

        // Optional configurations can be added here if needed
    }

    // Method to start OCR
    func startOCRProcess() {
        vidvOcrBuilder.start(vc: self, ocrDelegate: self)
    }

    // SDK Delegate - Logs handling
    func onOCRLog(log: VIDVOCR.VIDVEvent) {
        print("OCR Log - Key:", log.key ?? "")
    }

    func onOCRLog(log: VIDVOCR.VIDVError) {
        print("OCR Error - Message:", log.message)
    }

    // SDK Delegate - OCR Result handling
    func onOCRResult(result: VIDVOCRResponse) {
        switch result {
        case .success(let data):
            print("OCR Success:", data)
        case .builderError(let code, let message):
            print("Builder Error:", code, message)
        case .serviceFailure(let code, let message, let data):
            print("Service Failure:", code, message, data)
        case .userExit(let step, let data):
            print("User Exit at step:", step)
        case .capturedImages(capturedImageData: let capturedImageData):
            print("Captured Images:", capturedImageData)
        }
    }
}
