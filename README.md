iTunes Playlist Exporter
==============

A ruby script to export and convert iTunes playlists.

This script should make it easy to fill an SD card with music and M3U playlists suitable for stereos.

Installation
------------

This script needs ffmpeg installed and in your $PATH. The easiest way to do this is via homebrew. Otherwise you can grab a binary from [here](http://ffmpegmac.net/).

	$ brew install ffmpeg

Next install the scripts dependancies:

	$ [sudo] bundle install

Usage
-----

	./iTunesPlaylistExporter.rb <playlist name> <output path> <path to iTunes library XML>
