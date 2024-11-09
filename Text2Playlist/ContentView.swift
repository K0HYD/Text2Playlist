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
    @State private var songList: [SongInfo] = []

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
        }
    }

    // Your song list from a text file
    /* let songList = [
        SongInfo(title: "I Want to Hold Your Hand", artist: "The Beatles"),
        SongInfo(title: "She Loves You", artist: "The Beatles"),
        SongInfo(title: "Hello, Dolly!", artist: "Louis Armstrong"),
        SongInfo(title: "Oh, Pretty Woman", artist: "Roy Orbison")
    ] */

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

    // Call parseSongList only once to populate songList without recursion
    func loadInitialSongList() {
        let songData = """
            "I Want to Hold Your Hand - The Beatles”, “She Loves You - The Beatles";, "Hello  Dolly! - Louis Armstrong”, "Oh, Pretty Woman - Roy Orbison", “I Get Around - The Beach Boys”, “Everybody Loves Somebody - Dean Martin", "My Guy - Mary Wells", "We’ll Sing in the Sunshine - Gale Garnett", "Last Kiss - J. Frank Wilson & The Cavaliers", "Where Did Our Love Go - The Supremes", "People - Barbra Streisand", "Java - Al Hirt", "A Hard Day’s Night - The Beatles", "Love Me Do - The Beatles", "Do Wah Diddy Diddy - Manfred Mann", "Under the Boardwalk - The Drifters", "Chapel of Love - The Dixie Cups", "Suspicion - Terry Stafford", "Glad All Over - The Dave Clark Five", "Rag Doll - The Four Seasons", "Dawn (Go Away) - The Four Seasons", "Dancing in the Street - Martha and the Vandellas", "The Little Old Lady (from Pasadena) - Jan & Dean", "Ain’t That Loving You Baby - Elvis Presley", "Walk On By - Dionne Warwick", "Little Children - Billy J. Kramer & The Dakotas", "Come See About Me - The Supremes", "Because - The Dave Clark Five", "Fun, Fun, Fun - The Beach Boys", "Hey Little Cobra - The Rip Chords", "Let It Be Me - Betty Everett and Jerry Butler", "Twist and Shout - The Beatles", "House of the Rising Sun - The Animals", "G.T.O. - Ronny & the Daytonas", "Bread and Butter - The Newbeats", "Baby Love - The Supremes", "How Do You Do It? - Gerry & The Pacemakers", "It Hurts to Be in Love - Gene Pitney", "Wishin’ and Hopin’ - Dusty Springfield", "You Don’t Own Me - Lesley Gore", "A World Without Love - Peter and Gordon", "Anyone Who Had a Heart - Dionne Warwick", "Don’t Let the Rain Come Down (Crooked Little Man) - The Serendipity Singers", "I’m So Proud - The Impressions", "Java - Al Hirt", "Needles and Pins - The Searchers", "Fun, Fun, Fun - The Beach Boys", "Don’t Let the Sun Catch You Crying - Gerry & The Pacemakers", "Because - The Dave Clark Five", "We’ll Sing in the Sunshine - Gale Garnett", "C’mon and Swim - Bobby Freeman", "Do You Want to Know a Secret - The Beatles", "You Really Got Me - The Kinks", "Diane - The Bachelors", "Memphis - Johnny Rivers", "A Summer Song - Chad & Jeremy", "Remember (Walkin’ in the Sand) - The Shangri-Las", "Surfin’ Bird - The Trashmen", "Dead Man’s Curve - Jan & Dean", "Come a Little Bit Closer - Jay & The Americans", "Navy Blue - Diane Renay", "Little Honda - The Hondells", "Love Me With All Your Heart (Cuando Calienta el Sol) - Ray Charles Singers", "See the Funny Little Clown - Bobby Goldsboro", "I Love You More and More Every Day - Al Martino", "It's Over - Roy Orbison", "Ronnie - The Four Seasons", "Um, Um, Um, Um, Um, Um - Major Lance", "The Shoop Shoop Song (It's in His Kiss) - Betty Everett", "My Boy Lollipop - Millie Small", "Remembering When - The Innocents", "I Saw Her Standing There - The Beatles" ,"When I Grow Up (To Be a Man) - The Beach Boys", "The Girl from Ipanema - Stan Getz & Astrud Gilberto", "I Want to Hold Your Hand - The Beatles", "Because - The Dave Clark Five", "Any Way You Want It - The Dave Clark Five", "You Never Can Tell - Chuck Berry", "Long Tall Sally - The Beatles", "Leader of the Pack - The Shangri-Las", "Hey, Mr. Sax Man - Boots Randolph", "Bits and Pieces - The Dave Clark Five", "How Do You Do It? - Gerry & The Pacemakers", "Rag Doll - The Four Seasons", "Baby I Need Your Loving - The Four Tops", "What's Easy for Two Is So Hard for One - Mary Wells", "No Particular Place to Go - Chuck Berry", "Don't Throw Your Love Away - The Searchers", "Goodbye Baby (Baby Goodbye) - Solomon Burke", "Com e See About Me - The Supremes", "A Summer Song - Chad & Jeremy", "Glad All Over - The Dave Clark Five", "High Heel Sneakers - Tommy Tucker", "Needles and Pins - The Searchers", "Walk On By - Dionne Warwick", "Ain't That Peculiar - Marvin Gaye", "The House of the Rising Sun - The Animals", "Girl (Why You Wanna Make Me Blue) - The Temptations", "Under the Boardwalk - The Drifters", "Funny How Time Slips Away - Joe Hinton”
            """
        
        songList = parseSongList(from: songData)
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
                name: "Billboard 100 in 1964",
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
