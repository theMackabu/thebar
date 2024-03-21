import Yams
import SwiftUI
import Foundation


func extractURI(from urlString: String) -> (String?, String?) {
    if let url = URL(string: urlString), let scheme = url.scheme {
        let uri = urlString.replacingOccurrences(of: "\(scheme)://", with: "")
        return (uri, scheme)
    } else {
        return (urlString, nil)
    }
}

@main
struct TheBar: App {
    @State private var isLoading: Bool
    @State private var file: URL?
    @State private var links: [String]?
    
    @AppStorage("lastLoadedFile") private var lastLoadedFile: String = ""
    
    init() {
        _isLoading = State(initialValue: true)
        let yamlLinks = loadLinksFromYAML()
        _links = State(initialValue: yamlLinks)
        _file = State(initialValue: URL(string: lastLoadedFile))
        _isLoading = State(initialValue: false)
    }
    
    private func loadYamlFromLink(url: URL?) -> [String] {
        var list: [String] = []
        
        do {
            let fileData = try Data(contentsOf: url!)
            if let fileContents = String(data: fileData, encoding: .utf8) {
                if let yamlDict = try Yams.load(yaml: fileContents) as? [String: [String]],
                   let yamlLinks = yamlDict["links"] {
                    file = url
                    lastLoadedFile = url!.absoluteString
                    links = yamlLinks
                    list = yamlLinks
                } else {
                    print("Error parsing YAML")
                }
            } else {
                print("Error converting file data to string")
            }
        } catch {
            print("Error reading file: \(error)")
        }
        
        return list
    }
    
    @discardableResult
    private func loadLinksFromYAML() -> [String] {
        var list: [String] = []
        
        isLoading = true
        let file =
            (file != nil ? file : URL(string: lastLoadedFile))
        
        if file != nil {
            list = loadYamlFromLink(url: file)
        } else {
            let openPanel = NSOpenPanel()
            openPanel.allowedContentTypes = [.yaml]
            openPanel.allowsMultipleSelection = false
            
            if openPanel.runModal() == .OK {
                if let fileURL = openPanel.url {
                    list = loadYamlFromLink(url: fileURL)
                }
            }
        }
        
        isLoading = false
        return list
    }
    
    var body: some Scene {
        MenuBarExtra("The Bar", image: "MenuBarIcon") {
            if isLoading {
                Text("Loading links").foregroundColor(.gray)
            } else if let links = links {
                Text("Quick access")
                ForEach(links, id: \.self) { link in
                    if let url = URL(string: link) {
                        Link(destination: url) {
                            let uri = extractURI(from: link)
                            Text(uri.0 ?? "Invalid URL").badge(uri.1)
                        }
                    } else {
                        Text("Invalid URL: \(link)").foregroundColor(.red)
                    }
                }
            } else {
                Text("No links found").foregroundColor(.gray)
            }
            
            Divider()
                        
            Button(file != nil ? "Reload \(file!.lastPathComponent)" : "Load file") { loadLinksFromYAML() }
                .keyboardShortcut(file != nil ? "r" : "l", modifiers: [.command, .shift])
            
            if file != nil {
                Button("Change file") {
                    file = nil
                    lastLoadedFile = ""
                    loadLinksFromYAML()
                }
                .keyboardShortcut("l", modifiers: [.command, .shift])
            }
            
            Button("Quit") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        }
    }
}
