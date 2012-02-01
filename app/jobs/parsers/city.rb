require 'set'

class City

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

  def get_abbrev_matchers
    #These match states with two-letter abbreviations like IL, CA et al
    expressions = []
    @cities_states.each do |key, value|
      state_abbrev = @states_abbrev[value]
      pattern = /#{key.strip + ", " + state_abbrev}/
      expressions << pattern
    end
    expressions
  end

  def parse_cities(document)
    city = "Unknown"
    full_patterns = self.get_full_matchers 

    city
  end

end
