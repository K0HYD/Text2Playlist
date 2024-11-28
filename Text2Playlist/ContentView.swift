//
//  ContentView.swift
//  Text2Playlist
//
//  Created by Dale Puckett on 11/27/24.
//  Adding Button to load file
//

import Foundation
import MusicKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var fileContents: String = ""
    @State private var isFilePickerPresented = false
    @State private var statusMessages: [String] = ["Starting..."]
    @State private var songList: [SongInfo] = []
    @State private var isPromptingForFilename = false
    @State private var playlistName: String = ""
    @State private var foundSongs: [Song] = []

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(statusMessages, id: \.self) { message in
                        Text(message)
                            .padding(.bottom, 5)
                    }
                }
            }

            Button("Load File") {
                isFilePickerPresented = true
            }
            .fileImporter(
                isPresented: $isFilePickerPresented,
                allowedContentTypes: [.plainText],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result: result)
            }
            .padding()

            Button("Create Playlist") {
                isPromptingForFilename = true
            }
            .disabled(foundSongs.isEmpty) // Disable if no songs are found
            .padding()
        }
        .onAppear {
            Task {
                await requestMusicAuthorization()
            }
        }
        .sheet(isPresented: $isPromptingForFilename) {
            VStack {
                Text("Enter Playlist Name")
                    .font(.headline)
                    .padding()

                TextField("Playlist Name", text: $playlistName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                HStack {
                    Button("Cancel") {
                        isPromptingForFilename = false
                    }
                    .padding()

                    Button("Create") {
                        isPromptingForFilename = false
                        Task {
                            await createPlaylistWithName(playlistName, songs: foundSongs)
                        }
                    }
                    .padding()
                }
            }
            .padding()
        }
    }
    
    func createPlaylistWithName(_ name: String, songs: [Song]) async {
        guard !name.isEmpty else {
            addStatusMessage("Playlist name cannot be empty")
            return
        }
        
        do {
            let playlist = try await MusicLibrary.shared.createPlaylist(
                name: name,
                description: "Created using MusicKit",
                items: songs
            )
            addStatusMessage("Playlist created: \(playlist.name)")
        } catch {
            addStatusMessage("Error creating playlist: \(error.localizedDescription)")
        }
    }
    

    func handleFileImport(result: Result<[URL], Error>) {
        do {
            let fileURLs = try result.get()
            guard let fileURL = fileURLs.first else {
                fileContents = "No file selected."
                return
            }

            if fileURL.startAccessingSecurityScopedResource() {
                defer { fileURL.stopAccessingSecurityScopedResource() }
                fileContents = try String(contentsOf: fileURL, encoding: .utf8)
                
                loadInitialSongList() // Update the song list after loading the file
                
                Task {
                    await searchAndCreatePlaylist() // Trigger search
                }
            }
        } catch {
            fileContents = "Failed to load file: \(error.localizedDescription)"
        }
    }

    func loadInitialSongList() {
        songList = parseSongList(from: fileContents)
        print("Loaded songList: \(songList.map { "\($0.title) by \($0.artist)" })")
        addStatusMessage("Loaded \(songList.count) songs into the list.")
    }

    // Other functions remain unchanged...
    func requestMusicAuthorization() async {
        let status = await MusicAuthorization.request()
        if status == .authorized {
            print("Authorized to access Apple Music")
            addStatusMessage("Authorized to access Apple Music")
        } else {
            print("Not authorized to access Apple Music")
            addStatusMessage("Not authorized to access Apple Music")
        }
    }
    
    func parseSongList(from data: String) -> [SongInfo] {
        var parsedList: [SongInfo] = []
        let songEntries = data.split(separator: ",").map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "“", with: "").replacingOccurrences(of: "”", with: "").replacingOccurrences(of: "\"", with: "")
        }
        
        for entry in songEntries {
            let components = entry.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
            if components.count == 2 {
                let songTitle = components[0]
                let songArtist = components[1]
                parsedList.append(SongInfo(title: songTitle, artist: songArtist))
            }
        }
        return parsedList
    }
    
    func searchAppleMusic(for songInfo: SongInfo) async -> Song? {
        let searchTerm = "\(songInfo.title) \(songInfo.artist)"
        let searchRequest = MusicCatalogSearchRequest(term: searchTerm, types: [Song.self])
        
        do {
            let response = try await searchRequest.response()
            if let song = response.songs.first {
                return song
            } else {
                addStatusMessage("No results found for \(searchTerm)")
                return nil
            }
        } catch {
            addStatusMessage("Error searching Apple Music: \(error.localizedDescription)")
            return nil
        }
    }
    
    func searchAndCreatePlaylist() async {
        foundSongs = []
        print("Searching Apple Music for \(songList.count) songs")
        
        for songInfo in songList {
            print("Searching for: \(songInfo.title) by \(songInfo.artist)")
            if let song = await searchAppleMusic(for: songInfo) {
                print("Found song: \(song.title) by \(song.artistName)")
                foundSongs.append(song)
            } else {
                print("Could not find: \(songInfo.title) by \(songInfo.artist)")
            }
        }
        
        print("Total songs found: \(foundSongs.count)")
        addStatusMessage("Total songs found: \(foundSongs.count)")
    }
    
    func addStatusMessage(_ message: String) {
        DispatchQueue.main.async {
            statusMessages.append(message)
        }
    }
    
    struct SongInfo {
        let title: String
        let artist: String
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

