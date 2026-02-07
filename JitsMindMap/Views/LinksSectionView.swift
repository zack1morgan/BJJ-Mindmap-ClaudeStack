import SwiftUI

struct LinksSectionView: View {
    @Binding var links: [String]
    @State private var showingAddLink = false
    @State private var newLinkURL = ""
    @State private var showInvalidURLAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Links")
                    .font(.headline)

                Spacer()

                Button(action: { showingAddLink = true }) {
                    Label("Add Link", systemImage: "link.badge.plus")
                        .font(.subheadline)
                }
            }

            if links.isEmpty {
                Text("No links added yet")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(links.enumerated()), id: \.offset) { index, link in
                        LinkRowView(
                            link: link,
                            onDelete: { deleteLink(at: index) }
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddLink) {
            NavigationView {
                Form {
                    Section(header: Text("Enter URL")) {
                        TextField("https://example.com", text: $newLinkURL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                    }

                    Section {
                        Text("Add links to YouTube videos, instructionals, articles, or any web resource related to this technique.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .navigationTitle("Add Link")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            newLinkURL = ""
                            showingAddLink = false
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            addLink()
                        }
                        .disabled(newLinkURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
        .alert("Invalid URL", isPresented: $showInvalidURLAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please enter a valid URL starting with http:// or https://")
        }
    }

    private func addLink() {
        let trimmedURL = newLinkURL.trimmingCharacters(in: .whitespacesAndNewlines)

        // Validate URL
        guard !trimmedURL.isEmpty else { return }

        // Add https:// if no scheme provided
        var urlString = trimmedURL
        if !urlString.lowercased().hasPrefix("http://") && !urlString.lowercased().hasPrefix("https://") {
            urlString = "https://\(urlString)"
        }

        // Verify it's a valid URL
        guard URL(string: urlString) != nil else {
            showInvalidURLAlert = true
            return
        }

        links.append(urlString)
        newLinkURL = ""
        showingAddLink = false
    }

    private func deleteLink(at index: Int) {
        links.remove(at: index)
    }
}

// MARK: - Link Row View

struct LinkRowView: View {
    let link: String
    let onDelete: () -> Void

    var displayText: String {
        // Extract domain for display
        if let url = URL(string: link),
           let host = url.host {
            // Check for common video platforms
            if host.contains("youtube.com") || host.contains("youtu.be") {
                return "YouTube: \(url.lastPathComponent)"
            } else if host.contains("instagram.com") {
                return "Instagram: \(url.lastPathComponent)"
            } else if host.contains("vimeo.com") {
                return "Vimeo: \(url.lastPathComponent)"
            } else {
                return host
            }
        }
        return link
    }

    var icon: String {
        if let url = URL(string: link),
           let host = url.host {
            if host.contains("youtube.com") || host.contains("youtu.be") {
                return "play.rectangle.fill"
            } else if host.contains("instagram.com") {
                return "camera.fill"
            } else if host.contains("vimeo.com") {
                return "film.fill"
            }
        }
        return "link"
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(displayText)
                    .font(.subheadline)
                    .lineLimit(1)

                Text(link)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(uiColor: .systemGray6))
        .cornerRadius(8)
        .onTapGesture {
            if let url = URL(string: link) {
                UIApplication.shared.open(url)
            }
        }
    }
}
