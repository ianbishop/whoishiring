require 'uri'
require 'utils/trie'
require 'utils/classifier'

class Company
  
  def initialize(classifier)
    @trie = Trie.new
    File.open('lib/files/dict').readlines.each do |line|
      word = line.chomp
      @trie.push(word, word.length)
    end
    classifier.words['hiring'].keys.each do |key|
      @trie.push(key, key.length)
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
      # remove URLs out of the picture
      urls.each do |url|
        post = post.gsub(url, "")
      end
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
        name_occurences[word] += 1 if word.downcase =~ /^(http:\/\/)?^(www.)?\b#{potential_name}\b/
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
          potential_names << domain_and_tld.join("") # matches canvas
          potential_names << domain_and_tld.join(".") # matches visua.ly
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
    url = url.strip
    all_words = []
    words = []
    index = 0
    prev_length = url.length
    10.times do
      if index == url.length
        all_words << words
        p words
        k = words.pop.length
        prev_length = k-2
        index -= k
      end
      return [] if index == -1 or prev_length <= 0

      word = @trie.longest_prefix(url[index..index+prev_length])
      if word.nil?
        k = words.pop.length
        prev_length = k-2
        index -= k
      else
        prev_length = url.length-index
        words << word.capitalize
        index += word.length
      end
    end
    return []
  end

  def score_dict_url_candidate(post, all_words)
    scores = {}
    scores.default = 0

    all_words.each do |words|
      match_data = post.downcase.match(/\b#{words.join(" ")}\b/)

      unless match_data.nil?
        scores[words.join(" ")] =  match_data.length
      end
    end

    return scores
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
