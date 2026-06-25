import AppKit
import WebKit

/// Exports rendered HTML to PDF using a headless WKWebView.
enum HTMLExporter {
    static func exportPDF(html: String, to url: URL) {
        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 612, height: 792))
        webView.loadHTMLString(html, baseURL: nil)

        // Wait for load, then create PDF
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let config = WKPDFConfiguration()
            config.rect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter

            webView.createPDF(configuration: config) { result in
                switch result {
                case .success(let data):
                    try? data.write(to: url)
                case .failure(let error):
                    print("PDF export failed: \(error)")
                }
            }
        }
    }
}
