#!/usr/bin/env ruby

#############################################################################
# A script to convert and export m4a playlists to an SD Card
#
# usage: ./iTunesPlaylistExporter <playlist name> <output volume>
#
# TODO: sort the track list before work begins

require 'rubygems'
require 'bundler/setup'

require 'itunes/library'
require 'fileutils'
require 'colorize'
require 'ruby-progressbar'
require 'thread/pool'

# read args
playlist_name = ARGV[0]
output_volume = ARGV[1] ? ARGV[1] : "/Volumes/MUSIC_SD"
library_file = ARGV[2] ? ARGV[2] : File.join(ENV['HOME'],"/Music/iTunes/iTunes Music Library.xml")

if playlist_name.nil?
  puts "Usage: #{$0} <Playlist name> <output volume path> <path to library file>"
  exit()
end

# make sure our output folder exists
if !File.exist?(output_volume)
  FileUtils.mkdir_p(output_volume)
end

# open the mp3u playlist file
begin
  m3u_file = File.new(File.join(output_volume,"#{playlist_name}.m3u"), "w")
rescue
  puts "Unable to write to #{output_volume}"
  exit(1)
end

if !File.exist?(library_file)
  puts "Library file not found at #{library_file}"
  exit(1)
end

print "Reading library...".yellow

# Load the library
library = ITunes::Library.load(library_file)

puts "Done".yellow

# find the playlist
playlist = library.playlists.detect{|n| n.name == playlist_name}

if playlist.nil?
  puts "Playlist #{playlist_name} not found"
  exit
end

pb = ProgressBar.create(:title => "Tracks", :format => '%a %B %p%% %c/%C %e', :total => playlist.tracks.length)

p = Thread.pool(4)

at_exit do
  p.shutdown

  # close m3u file
  m3u_file.close()
end

# loop over each track
playlist.tracks.each do |t|
  
  source_filepath = CGI.unescape(URI.join(t.location).path)
  
  matches = /.*\/(.*)\/(.*)\/(.*)/.match(source_filepath)
  artist = matches[1]
  album = matches[2]
  source_track = matches[3]
  
  # check to see if destination mp3 exists
  destination_track = File.basename(source_filepath, ".m4a") + ".mp3"
  destination_folder = File.join("Music", artist, album)
  m3u_filepath = File.join(destination_folder, destination_track)
  
  destination_filepath = File.join(output_volume, m3u_filepath)
  
  if !File.exist?(destination_filepath)
    FileUtils.mkdir_p(File.join(output_volume,destination_folder))
    
    # puts "#{destination_filepath} doesn't exist...scheduling encoding".blue
    p.process {
      `ffmpeg -loglevel panic -i "#{source_filepath}" -q:a 2 "#{destination_filepath}"`
      m3u_file.puts(m3u_filepath)
      # puts "#{destination_filepath} finished".green
      pb.increment
    }
  else
    # puts "#{destination_filepath} exists...skipping".yellow
    m3u_file.puts(m3u_filepath)
    pb.increment
  end
end
