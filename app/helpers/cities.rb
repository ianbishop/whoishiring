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

  def get_full_matchers 
    expressions = []
    @cities_states.each do |key, value|
      full_pattern = /#{key.strip + ", " + value.strip}/
      expressions << full_pattern 
    end
    expressions
  end

  def parse_cities(document)
    city = "Unknown"
    @cities_states.each do |key, value|
      #Can we find full city, full state?
      if full_pattern.match(document) 
        city = key + " " + value
        break
      end

      #How about city, abbrev?
      unless @states_abbrev[value].nil?
        abbrev_pattern = /#{key.strip + ", " + @states_abbrev[value]}/
        if abbrev_pattern.match(document)
          city = key + " " + value
        end
      end
    end

    city
  end

end
