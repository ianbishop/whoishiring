require 'uri'
require 'trie.rb'

class CompanyParser
  
  def initialize
    @trie = Trie.new
    File.open('lib/files/dict').readlines.each do |line|
      word = line.chomp
      @trie.push(word, word.length)
    end
  end

  # Attempts a variety of parsing techniques,
  # returns "unknown" if there is no match.
  def parse(post, urls)
    post = post.gsub(/<\/?[^>]*>/, " ") # fixes situations like </p>CompanyName

    if urls.empty?
      # try ngrams based techniques
      ngrams_candidate = best_ngrams_match(post)
      return ngrams_candidate unless ngrams_candidate.nil?
    else
      # try URL based techniques
      full_url_candidate = best_full_url_match(post, urls)
      return full_url_candidate unless full_url_candidate.nil?

      dict_url_candidate = best_dict_url_match(post, urls)
      return dict_url_candidate unless dict_url_candidate.nil?
    end

    'unknown'
  end

  # Attempts to find full url matches in the string.
  # ie: www.google.com ->  "google"
  # returns nil if no match
  def best_full_url_match(post, urls)
    potential_names = potential_names_for_urls(urls)

    name_occurences = {}
    name_occurences.default = 0
    post.split(" ").each do |word|
      potential_names.each do |potential_name|
        name_occurences[potential_name.capitalize] += 1 if word.downcase =~ /^(http:\/\/)?^(www.)?\b#{potential_name}\b/
      end
    end

    if name_occurences.empty?
      nil
    else
      name_occurences.max[0]
    end
  end

  def potential_names_for_urls(urls)
    potential_names = []

    urls.each do |url|
      begin
         host_name = URI.parse(url).host
      rescue URI::Error => e 
      end

      unless host_name.nil?
        host_name = host_name[4..host_name.length] if host_name.start_with? 'www.'
        domain_and_tld = host_name.split(".")

        # one of three situations: subdomain or ccSLD (or both)
        if domain_and_tld.length > 2
          if domain_and_tld[1].length > 4
            # i'm willing to hedge you don't have a 4 letter domain
            # vs your ccSLD being greater than 4 chars, i'm looking at you brazil
            potential_names << domain_and_tld[1]
          else
            potential_names << domain_and_tld[0]
          end
        else
          potential_names << domain_and_tld[0]
          #potential_names << domain_and_tld.join("") # matches canv.as, visua.ly etc
        end
      end
    end
    
    potential_names
  end

  # Attempts to find dictionary word based url matches in the string
  # using a backtracking algorithm & a trie.
  # ie: www.mutualmobile.com -> Mutual Mobile
  # returns nil if no match
  def best_dict_url_match(post, urls) 
    scored_candidates = {}

    potential_names = potential_names_for_urls(urls)
    potential_names.each do |potential_name|
      candidate = backtrack_dict_url(potential_name)
      unless candidate.empty?
        scores = score_dict_url_candidate(post, candidate)
        unless scores.empty?
          max = scores.max
          scored_candidates[max[0]] = max[1]
        end
      end
    end

    if scored_candidates.empty?
      nil
    else
      scored_candidates.max[0]
    end
  end

  def backtrack_dict_url(url)
    words = []
    index = 0

    20.times do
      return words if index == url.length

      word = @trie.longest_prefix(url[index..url.length])
      if word.nil?
        index -= words.pop.length-1
      else
        words << word.capitalize
        index += word.length
      end
    end
    return []
  end

  def score_dict_url_candidate(post, words)
    #only implimenting x y z for now
    return { words.join(" ") => post.downcase.count(words.join(" ")) }
  end

  # Attempts to find least common word associations in the string
  # using an ngrams based algorithm vs other hired posts.
  # ie: www.mutualmobile.com -> Mutual followed by Mobile is
  # not a common association in English, therefore it may be easy to
  # distinguish it
  # returns nil if no match
  def best_ngrams_match(post)
    return nil
  end
end
