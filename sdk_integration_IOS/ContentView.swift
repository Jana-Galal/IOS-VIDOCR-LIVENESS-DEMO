import SwiftUI

struct ContentView: View {
    @StateObject private var SdkIntegration = sdkIntegration() // Use @StateObject

    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("OCR & LIVENESS SDK")
                .font(.title)

            // Start Scan Button
            Button("Start Scan") {
                SdkIntegration.startOCR() // Call startOCR directly
            }
            .font(.title2)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)

            // Access Token Display
            if !SdkIntegration.accessToken.isEmpty {
                Text("Access Token: \(SdkIntegration.accessToken)") // Show access token
                    .font(.subheadline)
                    .padding()
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(5)
            }

            // Error Message Display
            if !SdkIntegration.errorMessage.isEmpty {
                Text("Error: \(SdkIntegration.errorMessage)") // Show error message
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(5)
            }

            // OCR Result Message Display
            Text("OCR Result: \(SdkIntegration.ocrResultMessage)")
                .font(.subheadline)
                .padding()
                .background(Color.yellow.opacity(0.2))
                .cornerRadius(5)

            // Liveness Result Message Display
            Text("Liveness Result: \(SdkIntegration.livenessResultMessage)")
                .font(.subheadline)
                .padding()
                .background(Color.orange.opacity(0.2))
                .cornerRadius(5)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

