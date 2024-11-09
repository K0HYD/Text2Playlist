//
//  ContentView.swift
//  Text2Playlist
//
//  Created by Dale Puckett on 11/7/24.
//

import Foundation
import MusicKit
import SwiftUI

struct ContentView: View {
    @State private var statusMessages: [String] = ["Starting..."]

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
            .padding()
            .onAppear {
                Task {
                    await requestMusicAuthorization()
                    await searchAndCreatePlaylist()
                }
            }
        }
    }

    // Your song list from a text file
    let songList = [
        SongInfo(title: "I Want to Hold Your Hand", artist: "The Beatles"),
        SongInfo(title: "She Loves You", artist: "The Beatles"),
        SongInfo(title: "Hello, Dolly!", artist: "Louis Armstrong"),
        SongInfo(title: "Oh, Pretty Woman", artist: "Roy Orbison")
    ]

    struct SongInfo {
        let title: String
        let artist: String
    }

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

    func searchAppleMusic(for songInfo: SongInfo) async -> Song? {
        let searchTerm = "\(songInfo.title) \(songInfo.artist)"
        
        let searchRequest = MusicCatalogSearchRequest(term: searchTerm, types: [Song.self])
        
        do {
            let response = try await searchRequest.response()
            
            if let song = response.songs.first {
                return song
            } else {
                print("No results found for \(searchTerm)")
                addStatusMessage("No results found for \(searchTerm)")
                return nil
            }
        } catch {
            print("Error searching Apple Music: \(error.localizedDescription)")
            addStatusMessage("Error searching Apple Music: \(error.localizedDescription)")
            return nil
        }
    }

    func createAppleMusicPlaylist(with songs: [Song]) async {
        guard !songs.isEmpty else {
            print("No songs to add to the playlist")
            addStatusMessage("No songs to add to the playlist")
            return
        }
        
        do {
            let playlist = try await MusicLibrary.shared.createPlaylist(
                name: "Text2Playlist Test",
                description: "Created using MusicKit",
                items: songs
            )
            print("Playlist created: \(playlist.name)")
            addStatusMessage("Playlist created: \(playlist.name)")
        } catch {
            print("Error creating playlist: \(error.localizedDescription)")
            addStatusMessage("Error creating playlist: \(error.localizedDescription)")
        }
    }

    func searchAndCreatePlaylist() async {
        var foundSongs: [Song] = []
        
        for songInfo in songList {
            print("Searching for: \(songInfo.title) by \(songInfo.artist)")
            addStatusMessage("Searching for: \(songInfo.title) by \(songInfo.artist)")
            
            if let song = await searchAppleMusic(for: songInfo) {
                print("Found song: \(song.title) by \(song.artistName)")
                addStatusMessage("Found song: \(song.title) by \(song.artistName)")
                foundSongs.append(song)
            } else {
                print("Could not find \(songInfo.title) by \(songInfo.artist)")
                addStatusMessage("Could not find \(songInfo.title) by \(songInfo.artist)")
            }
        }
        
        print("Total songs found: \(foundSongs.count)")
        if !foundSongs.isEmpty {
            addStatusMessage("Total songs found: \(foundSongs.count)")
            print("Songs found:")
            for song in foundSongs {
                print("- \(song.title) by \(song.artistName)")
                addStatusMessage("- \(song.title) by \(song.artistName)")
            }
        } else {
            addStatusMessage("No songs were found.")
            print("No songs were found.")
        }
        
        await createAppleMusicPlaylist(with: foundSongs)
    }

    // Helper function to add a status message and update the UI
    func addStatusMessage(_ message: String) {
        DispatchQueue.main.async {
            statusMessages.append(message)
        }
    }
}
