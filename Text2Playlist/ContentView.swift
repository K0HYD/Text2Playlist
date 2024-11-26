//
//  ContentView.swift
//  Text2Playlist
//
//  Created by Dale Puckett on 11/25/24.
//

import Foundation
import MusicKit
import SwiftUI

struct ContentView: View {
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
            .padding()
            .onAppear {
                loadInitialSongList()
                Task {
                    await requestMusicAuthorization()
                    await searchAndCreatePlaylist()
                }
            }

            Button("Create Playlist") {
                isPromptingForFilename = true
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
    }

    struct SongInfo {
        let title: String
        let artist: String
    }

 /*   func loadInitialSongList() {
        let songData = """
        "I Want to Hold Your Hand - The Beatles",
        "She Loves You - The Beatles",
        "Hello, Dolly! - Louis Armstrong",
        "Oh, Pretty Woman - Roy Orbison",
        "I Get Around - The Beach Boys",
        "Everybody Loves Somebody - Dean Martin"
        """
        songList = parseSongList(from: songData)
    } */
    
    // Call parseSongList only once to populate songList without recursion
    func loadInitialSongList() {
        let songData = """
    "Tossin’ and Turnin’ - Bobby Lewis",
    "I Fall to Pieces - Patsy Cline",
    "Michael - The Highwaymen",
    "Crying - Roy Orbison",
    "Runaway - Del Shannon",
    "My True Story - The Jive Five",
    "Pony Time - Chubby Checker",
    "Wheels - The String-A-Longs",
    "Raindrops - Dee Clark",
    "Wooden Heart - Joe Dowell",
    "Exodus - Ferrante & Teicher",
    "Take Good Care of My Baby - Bobby Vee",
    "Calcutta - Lawrence Welk and His Orchestra",
    "Runaround Sue - Dion",
    "Quarter to Three - Gary U.S. Bonds",
    "Travelin’ Man - Ricky Nelson",
    "Dedicated to the One I Love - The Shirelles",
    "The Lion Sleeps Tonight - The Tokens",
    "Blue Moon - The Marcels",
    "Mother-In-Law - Ernie K-Doe",
    "Hurt - Timi Yuro",
    "Please Mr. Postman - The Marvelettes",
    "Does Your Chewing Gum Lose Its Flavor - Lonnie Donegan",
    "Hello Mary Lou - Ricky Nelson",
    "Where the Boys Are - Connie Francis",
    "Will You Love Me Tomorrow - The Shirelles",
    "Last Night - The Mar-Keys",
    "Surrender - Elvis Presley",
    "Angel Baby - Rosie and the Originals",
    "Hit the Road Jack - Ray Charles",
    "A Hundred Pounds of Clay - Gene McDaniels",
    "Good Time Baby - Bobby Rydell",
    "Apache - Jørgen Ingmann and His Guitar",
    "This Time - Troy Shondell",
    "Please Love Me Forever - Cathy Jean and the Roommates",
    "Bristol Stomp - The Dovells",
    "Little Sister - Elvis Presley",
    "Every Beat of My Heart - Gladys Knight and the Pips",
    "The Way You Look Tonight - The Lettermen",
    "Big Bad John - Jimmy Dean",
    "Moody River - Pat Boone",
    "Hats Off to Larry - Del Shannon",
    "Goodbye Cruel World - James Darren",
    "School Is Out - Gary U.S. Bonds",
    "The Boll Weevil Song - Brook Benton",
    "Don’t Bet Money Honey - Linda Scott",
    "Ya Ya - Lee Dorsey",
    "Let Me Belong to You - Brian Hyland",
    "Mexico - Bob Moore and His Orchestra",
    "Asia Minor - Kokomo",
    "You Can Depend on Me - Brenda Lee",
    "Barbara Ann - The Regents",
    "You Don’t Know What You’ve Got (Until You Lose It) - Ral Donner",
    "Baby Sittin’ Boogie - Buzz Clifford",
    "Walk on By - Leroy Van Dyke",
    "Sad Movies (Make Me Cry) - Sue Thompson",
    "Tonight (Could Be the Night) - The Velvets",
    "I Love How You Love Me - The Paris Sisters",
    "Calendar Girl - Neil Sedaka",
    "Let There Be Drums - Sandy Nelson",
    "Without You - Johnny Tillotson",
    "One Mint Julep - Ray Charles",
    "Take Five - The Dave Brubeck Quartet",
    "Dum Dum - Brenda Lee",
    "Riders in the Sky - Lawrence Welk",
    "You Must Have Been a Beautiful Baby - Bobby Darin",
    "Baby Blue - The Echoes",
    "The Mountain’s High - Dick and Dee Dee",
    "Tower of Strength - Gene McDaniels",
    "Fool #1 - Brenda Lee",
    "Pretty Little Angel Eyes - Curtis Lee",
    "Rubber Ball - Bobby Vee",
    "Breakin’ in a Brand New Broken Heart - Connie Francis",
    "Together - Connie Francis",
    "Happy Birthday Sweet Sixteen - Neil Sedaka",
    "Run to Him - Bobby Vee",
    "Stand by Me - Ben E. King",
    "Cupid - Sam Cooke",
    "What a Sweet Thing That Was - The Shirelles",
    "Tonight My Love, Tonight - Paul Anka",
    "Flaming Star - Elvis Presley",
    "Little Devil - Neil Sedaka",
    "Big John - The Shirelles",
    "(Marie’s the Name) His Latest Flame - Elvis Presley",
    "I’m Gonna Knock on Your Door - Eddie Hodges",
    "Life Is But a Dream - The Harptones",
    "I Understand - The G-Clefs",
    "Jimmy’s Girl - Johnny Tillotson",
    "Somebody Nobody Wants - Dion",
    "Please Stay - The Drifters",
    "The Fly - Chubby Checker",
    "Everlovin’ - Rick Nelson",
    "Peppermint Twist - Joey Dee and the Starliters",
    "Little Miss Lonely - Helen Shapiro",
    "Just Out of Reach (Of My Two Open Arms) - Solomon Burke",
    "The Bridge of Love - Joe Dowell",
    "On the Rebound - Floyd Cramer",
    "A Little Bit of Soap - The Jarmels",
    "One Track Mind - Bobby Lewis",
    "Halfway to Paradise - Tony Orlando"
"""
        songList = parseSongList(from: songData)
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

        for songInfo in songList {
            addStatusMessage("Searching for: \(songInfo.title) by \(songInfo.artist)")

            if let song = await searchAppleMusic(for: songInfo) {
                addStatusMessage("Found song: \(song.title) by \(song.artistName)")
                foundSongs.append(song)
            } else {
                addStatusMessage("Could not find \(songInfo.title) by \(songInfo.artist)")
            }
        }

        addStatusMessage("Total songs found: \(foundSongs.count)")
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

    func addStatusMessage(_ message: String) {
        DispatchQueue.main.async {
            statusMessages.append(message)
        }
    }
}
