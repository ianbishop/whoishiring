require 'set'

class City

  def initialize
    @states_abbrev = {}
    @monikers = {}
    @cities_states = {}
    @matchers_cities = {}
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
      state_abbrev = @states_abbrev[value]
      full_pattern = /#{key.strip + "\, " + value.strip}/
      expressions << full_pattern
      @matchers_cities[full_pattern] = key.strip + ", " + state_abbrev.strip
    end
    expressions
  end

  def match_document(document)
    city = "Unknown"
    full_matchers = get_full_matchers
    abbrev_matchers = get_abbrev_matchers
    
    #Try to match a full city first
    full_matchers.each do |matcher|
      if matcher.match(document)
        city = @matchers_cities[matcher]
        return city
      end
    end

    #Try to match a city with an abbrev
    abbrev_matchers.each do |matcher|
      if matcher.match(document)
        city = @matchers_cities[matcher]
        return city
      end
    end

    city
  end

  def get_abbrev_matchers
    #These match states with two-letter abbreviations like IL, CA et al
    expressions = []
    @cities_states.each do |key, value|
      state_abbrev = @states_abbrev[value]
      pattern = /#{key.strip + "\, " + state_abbrev.strip}/
      expressions << pattern
      @matchers_cities[pattern] = key.strip + ", " + state_abbrev.strip
    end
    expressions
  end

  def parse_cities(document)
    city = "Unknown"
    full_patterns = self.get_full_matchers 
    partial_patterns = self.get_abbrev_matchers

    full_patterns.each do |full|
      if full.match(document)
      end
    end

    city
  end

end
