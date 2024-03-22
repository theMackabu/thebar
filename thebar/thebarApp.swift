import Yams
import SwiftUI
import Foundation

typealias Item = [String: Any]

func extractURI(from urlString: String) -> (String?, String?) {
    if let url = URL(string: urlString), let scheme = url.scheme {
        let uri = urlString.replacingOccurrences(of: "\(scheme)://", with: "")
        return (uri, scheme)
    } else {
        return (urlString, nil)
    }
}

func extractLinks(from linkData: [Item]) -> [(String, String?)]? {
    var extractedLinks: [(String, String?)] = []
    for item in linkData {
        item.forEach { key, value in
            if value is NSNull {
                extractedLinks.append((key, nil))
            } else {
                extractedLinks.append((key, value as? String))
            }
            
        }
    }
    return extractedLinks.isEmpty ? nil : extractedLinks
}

@main
struct TheBar: App {
    @State private var isLoading: Bool
    @State private var file: URL?
    @State private var links: [Item]?
    
    @AppStorage("lastLoadedFile") private var lastLoadedFile: String = ""
    
    init() {
        _isLoading = State(initialValue: true)
        let yamlLinks = loadLinksFromYAML()
        _links = State(initialValue: yamlLinks)
        _file = State(initialValue: URL(string: lastLoadedFile))
        _isLoading = State(initialValue: false)
    }
    
    private func loadYamlFromLink(url: URL?) -> [Item]? {
        var list: [Item]? = []
        
        do {
            let fileData = try Data(contentsOf: url!)
            if let fileContents = String(data: fileData, encoding: .utf8) {
                if let yamlDict = try Yams.load(yaml: fileContents) as? [String: [Item]],
                   let parsed = yamlDict["links"] {
                    file = url
                    lastLoadedFile = url!.absoluteString
                    links = parsed
                    list = parsed
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
    private func loadLinksFromYAML() -> [Item] {
        var list: [Item] = []
        
        isLoading = true
        let file =
        (file != nil ? file : URL(string: lastLoadedFile))
        
        if file != nil {
            list = loadYamlFromLink(url: file)!
        } else {
            let openPanel = NSOpenPanel()
            openPanel.allowedContentTypes = [.yaml]
            openPanel.allowsMultipleSelection = false
            
            if openPanel.runModal() == .OK {
                if let fileURL = openPanel.url {
                    list = loadYamlFromLink(url: fileURL)!
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
                let groupedLinks = Dictionary(grouping: extractLinks(from: links)!) { $0.1 }
                ForEach(groupedLinks.sorted(by: { $0.key ?? "" < $1.key ?? "" }), id: \.key) { value, links in
                    Section(header: Text(value ?? "Quick Access")) {
                        ForEach(links, id: \.0) { link, value in
                            if let url = URL(string: link) {
                                Link(destination: url) {
                                    let uri = extractURI(from: link)
                                    Text(uri.0 ?? "Invalid URL").badge(uri.1 == "https" || uri.1 == "http" ? nil : uri.1)
                                }
                            } else {
                                Text("Invalid URL: \(link)").foregroundColor(.red)
                            }
                        }
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
