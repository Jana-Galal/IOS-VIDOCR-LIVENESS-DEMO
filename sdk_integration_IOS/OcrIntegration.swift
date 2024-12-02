import Foundation
import UIKit
import VIDVOCR

class OCRIntegration: NSObject, VIDVOCRDelegate, VIDVLogsDelegate {
    
    // Singleton instance for easy access
    static let shared = OCRIntegration()
    
    // SDK Builder instance
    private var vidvOcrBuilder = OCRBuilder()
    
    // Store necessary credentials and access token
    private var accessToken: String = ""
    private let username = "valify__73348_integration_bundle"
    private let password = "FYmSYPF3sIKM1368"
    private let clientId = "cRZhCrZi8MDUXdmyAZqqBz7M9aZcSp2hrJBpENt7"
    private let clientSecret = "bMcB6LQ7uY9EIHqGONqKYkhlgJoWDzaIrfbZFM9cYZb5AhFDaJ1tF3YeGpSUFy9g963HCf38qRjap5JWnDDQKVeCjtdUclf2t6NfuBxYOSIT2PlX6Yi8dWWXe45TYW8d"
    private let bundleKey = "2b92d93b823142899e70eede53182735"
    
    // Completion callback for OCR results
    var ocrCompletion: ((String?, Error?) -> Void)?
    
    // Private initializer to enforce singleton usage
    private override init() {
        super.init()
    }
    
    // Public method to start OCR process
    func startOCR(completion: @escaping (String?, Error?) -> Void) {
        self.ocrCompletion = completion
        
        generateAccessToken { [weak self] token, error in
            guard let self = self else { return }
            
            if let token = token {
                self.accessToken = token
                self.configureOcr(with: token)
                
                DispatchQueue.main.async {
                    if let viewController = UIApplication.shared.windows.first?.rootViewController {
                        self.vidvOcrBuilder.start(vc: viewController, ocrDelegate: self)
                    }
                }
            } else {
                completion(nil, error) // Pass error if token generation fails
            }
        }
    }
    
    // Generate access token from API
    private func generateAccessToken(completion: @escaping (String?, Error?) -> Void) {
        let urlString = "https://valifystage.com/api/o/token/"
        guard let url = URL(string: urlString) else {
            completion(nil, NSError(domain: "Invalid URL", code: -1, userInfo: nil))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Form URL-encoded request body
        let bodyComponents = [
            "username": username,
            "password": password,
            "client_id": clientId,
            "client_secret": clientSecret,
            "grant_type": "password"
        ]
        .map { "\($0)=\($1)" }
        .joined(separator: "&")
        
        request.httpBody = bodyComponents.data(using: .utf8)
        
        // Execute network request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, NSError(domain: "No data", code: -1, userInfo: nil))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let token = json["access_token"] as? String {
                    completion(token, nil)
                } else {
                    completion(nil, NSError(domain: "Token Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid token response"]))
                }
            } catch {
                completion(nil, error)
            }
        }
        task.resume()
    }
    
    // Configure OCR SDK with access token
    private func configureOcr(with token: String) {
        vidvOcrBuilder = vidvOcrBuilder
            .setBundleKey(bundleKey)
            .setBaseUrl("https://www.valifystage.com/")
            .setAccessToken(token)
            .setLogsDelegate(self)
    }
    
    // Handle OCR logs
    func onOCRLog(log: VIDVOCR.VIDVEvent) {
        print("LOG Event 🏳️--------------")
        print("Key:", log.key ?? "")
        print("Session ID:", log.sessionId ?? "")
        print("Date:", log.date)
        print("Timestamp:", log.timestamp ?? "")
        print("Type:", log.type ?? "")
        print("Screen:", log.screen ?? "")
    }
    
    func onOCRLog(log: VIDVOCR.VIDVError) {
        print("LOG Error 🚩--------------")
        print("Code:", log.code ?? 0)
        print("Message:", log.message)
        print("Session ID:", log.sessionId ?? "")
        print("Date:", log.date)
        print("Timestamp:", log.timestamp ?? "")
        print("Type:", log.type ?? "")
        print("Screen:", log.screen ?? "")
    }
    
    // Handle OCR results
    func onOCRResult(result: VIDVOCRResponse) {
        switch result {
        case .success(let data):
            if let extractedText = extractText(from: data) {
                ocrCompletion?(extractedText, nil)
            } else {
                ocrCompletion?(nil, NSError(domain: "DataError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to extract text from OCR result"]))
            }
        case .builderError(let code, let message):
            ocrCompletion?(nil, NSError(domain: "BuilderError", code: code, userInfo: [NSLocalizedDescriptionKey: message]))
        case .serviceFailure(let code, let message, _):
            ocrCompletion?(nil, NSError(domain: "ServiceError", code: code, userInfo: [NSLocalizedDescriptionKey: message]))
        case .userExit:
            print("User exited the OCR process.")
        case .capturedImages(let capturedImageData):
            print("Captured Images: \(capturedImageData)")
        }
    }
    
    // Extract text from OCR data
    private func extractText(from data: Any) -> String? {
        if let dictionary = data as? [String: Any],
           let text = dictionary["text"] as? String {
            return text
        } else if let jsonData = try? JSONSerialization.data(withJSONObject: data, options: []),
                  let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        return nil
    }
}

