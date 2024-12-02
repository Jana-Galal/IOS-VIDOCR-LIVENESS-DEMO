import Foundation
import VIDVOCR
import VIDVLiveness
import UIKit
import Combine
import Toast_Swift

class sdkIntegration: UIViewController, VIDVOCRDelegate, VIDVLogsDelegate, ObservableObject, VIDVLivenessDelegate{
    // Ensure it conforms to ObservableObject
    @Published var ocrResultMessage: String = "" // Publish OCR result message
    @Published var livenessResultMessage: String = "" // Publish Liveness result message

    
    // SDK Builder instance
    private var vidvOcrBuilder = OCRBuilder()
    private var vidvLivenessBuilder =  VIDVLivenessBuilder()
    
    // Store credentials( The credentials are out in app interface for testing purposes it's recommended to put in your app backend for better security)
    private let username = "Enter your user name here"
    private let password = "Enter your password here"
    private let clientId = "Enter your client id here"
    private let clientSecret = "Enter your client secret here"
    private let bundleKey = "Enter your bundle key here"
    private let baseURL = "Enter your base url here"
    
    @Published var accessToken: String = "" // Publish access token to UI
    @Published var errorMessage: String = "" // Publish error message to UI
    
    // Generate access token from API to connect to the SDK
    func generateAccessToken(completion: @escaping (String?, Error?) -> Void) {
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
            DispatchQueue.main.async {
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
        }
        task.resume()
    }
    
    // Start OCR process including token generation
    func startOCR() {
        generateAccessToken { [weak self] token, error in
            guard let self = self else { return }
            
            if let token = token {
                self.accessToken = token // Update published access token
                self.errorMessage = "" // Clear any previous error message
                
                //Giving the OCR builder required configurations
                self.vidvOcrBuilder = self.vidvOcrBuilder
                    .setBundleKey(self.bundleKey)
                    .setBaseUrl(self.baseURL)
                    .setAccessToken(token)
                    // This is an example of  optional configurations
                    .setLogsDelegate(self)
                    .setReviewData(false)
                
                // Find the root view controller to present from
                if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                    self.vidvOcrBuilder.start(vc: rootVC, ocrDelegate: self) // Present using the root view controller
                    print("OCR started with access token: \(token)") // Log to confirm the method was called
                } else {
                    print("Error: No root view controller found.")
                }
            } else if let error = error {
                self.accessToken = "" // Clear access token on error
                self.errorMessage = error.localizedDescription // Update error message
                print("Failed to generate access token: \(error.localizedDescription)")
            }
        }
    }
    //start liveness process
    func startLiveness(transactionFrontId : String){
        self.vidvLivenessBuilder = self.vidvLivenessBuilder
            .setBundleKey(self.bundleKey)
            .setBaseURL(self.baseURL)
            .setAccessToken(accessToken)
            .setFrontTransactionID(transactionFrontId)
        if let rootVC = UIApplication.shared.windows.first?.rootViewController {
            self.vidvLivenessBuilder.start(vc: rootVC, livenessDelegate:self)
            print("Liveness started") // Log to confirm the method was called
        } else {
            print("Error: No root view controller found.")
        }
    }
    
    //Function Logging OCR logs
    func onOCRLog(log: VIDVOCR.VIDVEvent) {
        print("LOG Event 🏳️--------------")
        print("LOG key:", log.key ?? "")
        print("LOG sessionId:", log.sessionId ?? "")
        print("LOG date:", log.date)
        print("LOG timestamp:", log.timestamp ?? "")
        print("LOG type:", log.type ?? "")
        print("LOG screen:", log.screen ?? "")
    }
    //Function Logging OCR logs errors
    func onOCRLog(log: VIDVOCR.VIDVError) {
        print("LOG Error 🚩--------------")
        print("LOG code:", log.code ?? 0)
        print("LOG message:", log.message)
        print("LOG sessionId:", log.sessionId ?? "")
        print("LOG date:", log.date)
        print("LOG timestamp:", log.timestamp ?? "")
        print("LOG type:", log.type ?? "")
        print("LOG screen:", log.screen ?? "")
    }
    //Handling OCR response
    func onOCRResult(result: VIDVOCRResponse) {
        switch result {
        case .success(let data):
            //This is excecuted when the ocr is completed successfully
            //Getting transaction front id to pass it to liveness for facematch to work
            // data of type VIDVOCRResult
            let transactionFrontId = data?.ocrResult?.transactionIdFront ?? ""
            ocrResultMessage = "OCR Success! Transaction ID: \(transactionFrontId)"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                //Call Liveness sdk on OCR success
                self.startLiveness(transactionFrontId: transactionFrontId)
            }
        case .builderError(let code, let message):
            // Process terminated due to an error in the builder
            // builder error code & error message
            ocrResultMessage = "OCR Error! Code: \(code), Message: \(message)"
        case .serviceFailure(let code, let message, let data):
            // service faluire error code & error message & data of type VIDVOCRResult
            //Process finished with the user's failure to pass the service requirements
            ocrResultMessage = "Service Error! Code: \(code), Message: \(message)"
        case .userExit(let step, let data):
            // last step in the SDK & data of type VIDVOCRResult
            //Process terminated by the user with no errors
            ocrResultMessage = "User exited at step \(step)"
        case .capturedImages(let capturedImageData):
            //Images captured are returned in real-time
            // capturedImageData of type CapturedImageDat
            ocrResultMessage = "Image Captured"
        }
    }
    
    //Handling Liveness results
    func onLivenessResult(_ result: VIDVLiveness.VIDVLivenessResponse) {
            switch result {
            case .success(let data):
                //This is excecuted when the ocr is completed successfully
                // data of type VIDVOCRResult
                livenessResultMessage = "Liveness Success!"
            case .builderError(let code, let message):
                // builder error code & error message
                livenessResultMessage = "Liveness Error! Code: \(code), Message: \(message)"
            case .serviceFailure(let code, let message, let data):
                // service faluire error code & error message & data of type VIDVOCRResult
                livenessResultMessage = "Service Error! Code: \(code), Message: \(message)"
            case .userExited(let data, let step):
                // last step in the SDK & data of type VIDVOCRResult
                livenessResultMessage = "User exited at step \(step)"
            case .capturedActions(let capturedActions):
                // capturedImageData of type CapturedImageData
                livenessResultMessage = "Liveness Image Captured"
            }
        }

    
    
}
