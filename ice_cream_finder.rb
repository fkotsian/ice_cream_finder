#!/usr/bin/env ruby

require 'json'
require 'nokogiri'
require 'addressable/uri'
require 'rest-client'

api_key = nil
begin
  api_key = File.read('./secret.rb').chomp
rescue
  puts "Unable to read './secret.rb'. Please provide a valid Google API key."
  exit
end

def print_place_directions(places)
  places.each do |place|
    puts place[:name]
    puts place[:directions].join("\n")
    puts
  end
end

def get_location
  url = Addressable::URI.new(
    :scheme => "https",
    :host => "maps.googleapis.com",
    :path => "/maps/api/geocode/json",
    :query_values => {
      :address => "1061 Market Street, San Francisco",
      :sensor => false
    }
  ).to_s

  raw_json = RestClient.get(url)
  location = JSON.parse(raw_json)

  lat =  location['results'].first['geometry']['location']['lat']
  long = location['results'].first['geometry']['location']['lng']
  [lat, long]
end

def get_nearby_places(lat, long, api_key)
  place_url = Addressable::URI.new(
    :scheme => "https",
    :host => "maps.googleapis.com",
    :path => "maps/api/place/nearbysearch/json",
    :query_values => {
      :location => "#{lat},#{long}",
      :radius => 500,
      :sensor => false,
      :keyword => 'ice+cream',
      :rankby => :prominence,
      :key => api_key    }
  ).to_s

  raw_json_place_data = RestClient.get(place_url)

  place_data = JSON.parse(raw_json_place_data)

  places = []

  place_data['results'].each do |place|
    places << {
      name: place['name'],
      lat: place['geometry']['location']['lat'],
      long: place['geometry']['location']['lng'],
      directions: nil
    }
  end

  places
end

def get_directions(lat, long, places)
  places.each do |place|

    dir_url = Addressable::URI.new(
    :scheme => "https",
    :host => "maps.googleapis.com",
    :path => "/maps/api/directions/json",
    :query_values => {
      :origin => "#{lat},#{long}",
      :destination => "#{ place[:lat] }, #{ place[:long] }",
      :sensor => false,
      :mode => 'walking' }
    ).to_s

    raw_direction_data = RestClient.get(dir_url)

    dir_data = JSON.parse(raw_direction_data)

    steps = dir_data['routes'].first['legs'].first['steps'].map do |step|
      Nokogiri::HTML(step['html_instructions']).text
    end
    place[:directions] = steps
  end

  places
end

if $PROGRAM_NAME == __FILE__
  lat, long = get_location
  places = get_nearby_places(lat, long, api_key)
  places = get_directions(lat, long, places)
  print_place_directions(places)
end
