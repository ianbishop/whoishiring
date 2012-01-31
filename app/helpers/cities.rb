require 'set'

class Cities

  def initialize
    @states_abbrev = {}
    @monikers = {}
    @cities_states = {}
    File.open('lib/files/city_states.txt').readlines.each do |line|
      unless line.nil?
        state_tuple = line.strip.split(',')
        @cities_states[state_tuple[0]] = state_tuple[1]
        @states_abbrev[state_tuple[1]] = state_tuple[2]
      end
    end
  end

  def parse_cities(document)
    city = "Unknown"
    docset = Set.new(document.split(" "))
    @cities_states.each do |key, value|
      if docset.include?(key.downcase)
        city = key + " " + value 
      end
    end

    city
  end

end
