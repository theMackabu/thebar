import Foundation
import SwiftUI
import Yams

func extractURI(from urlString: String) -> String? {
  if let url = URL(string: urlString), let scheme = url.scheme {
    let uri = urlString.replacingOccurrences(of: "\(scheme)://", with: "")
    return uri
  } else {
    return urlString
  }
}

@main
struct TheBar: App {
  @State private var isLoading = false
  @State private var file: URL? = nil
  @State private var links: [String]? = nil

  private func loadYamlFromLink(url: URL?) {
    do {
      let fileData = try Data(contentsOf: url!)
      if let fileContents = String(data: fileData, encoding: .utf8) {
        if let yamlDict = try Yams.load(yaml: fileContents) as? [String: [String]],
          let yamlLinks = yamlDict["links"]
        {
          file = url
          links = yamlLinks
        } else {
          print("Error parsing YAML")
        }
      } else {
        print("Error converting file data to string")
      }
    } catch {
      print("Error reading file: \(error)")
    }
  }

  private func loadLinksFromYAML() {
    if file != nil {
      loadYamlFromLink(url: file)
    } else {
      let openPanel = NSOpenPanel()
      openPanel.allowedContentTypes = [.yaml]
      openPanel.allowsMultipleSelection = false

      if openPanel.runModal() == .OK {
        if let fileURL = openPanel.url {
          loadYamlFromLink(url: fileURL)
        }
      }
    }
  }

  var body: some Scene {
    MenuBarExtra("The Bar", image: "MenuBarIcon") {
      Text("Quick links")

      if isLoading {
        Text("Loading links").foregroundColor(.gray)
      } else if let links = links {
        ForEach(links, id: \.self) { link in
          if let url = URL(string: link) {
            Link(destination: url) {
              Text(extractURI(from: link) ?? "Invalid URL")
            }
          } else {
            Text("Invalid URL: \(link)").foregroundColor(.red)
          }
        }
      } else {
        Text("No links found").foregroundColor(.gray)
      }

      Divider()

      Button(file != nil ? "Reload \(file!.lastPathComponent)" : "Load file") {
        isLoading = true
        loadLinksFromYAML()
        isLoading = false
      }
      .keyboardShortcut("l", modifiers: [.command, .shift])

      Button("Quit") { NSApplication.shared.terminate(nil) }
        .keyboardShortcut("q")
    }
  }
}
