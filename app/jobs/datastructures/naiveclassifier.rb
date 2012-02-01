require 'stemmer'
require 'set'

class Classifier
    attr_accessor :word_occurrences, :numwords, :words
               
   def initialize
       @word_occurrences = {}
       @word_occurrences.default(0)
       @common_words = Set.new [
           "a", "able", "about", "across", "after", "all", "almost",
           "also", "am", "among", "an", "and", "any", "are", "as", 
           "at", "be", "because", "been", "but", "by", "can", "cannot", 
           "could", "dear", "did", "do", "does", "either", "else",
           "ever", "every", "for", "from", "get", "got", "had",
           "has", "have", "he", "her", "hers", "him", "his", "how", 
           "however", "i", "if", "in", "into", "is", "it", "its",
           "just", "least", "let", "like", "likely", "may", "me", 
           "might", "most", "must", "my", "neither", "no", "nor", 
           "not", "of", "off", "often", "on", "only", "or", "other",
           "our", "own", "rather", "said", "say", "says", "she",
           "should", "since", "so", "some", "than", "that", "the",
           "their", "them", "then", "there", "these", "they",
           "this", "tis", "to", "too", "twas", "us", "wants", 
           "was", "we", "were", "what", "when", "where", "which",
           "while", "who", "whom", "why", "will", "with", "would",
           "yet", "you", "your"]
        @categories_documents = Hash.new
        @categories_documents["hiring"] = 0
        @categories_documents["not hiring"] = 0
        @categories_words = Hash.new
        @categories_words["hiring"] = 0
        @categories_words["not hiring"] = 0
        @words = Hash.new
        @words["hiring"] = Hash.new
        @words["not hiring"] = Hash.new
        @numwords = 0
        @threshold = 1.5
        @total_documents = 0
    end

    def train(category, doc_file)
        File.open(doc_file, "r") do |document|
            words = document.read().downcase
            words = words.gsub(/<.*>.*<\/.*>/, '').gsub(/<.*>/,'').gsub(/[\.\'\"\;\!\:\(\)\-\{\}]/,'').split(' ')
            words.each do |word|
                if !@common_words.include?(word)
                    if @words[category].has_key?(word)
                        @words[category][word] += 1
                    else
                        @words[category][word] = 1
                    end
                    @numwords += 1
                    @categories_words[category] += 1
                end
            end
        end
        @categories_documents[category] += 1
        @total_documents += 1
    end

    def occurrences(word)
        return @word_occurrences[word]
    end

    def unique_words
        return @word_occurrences.length
    end

    def word_probability(category, word)
        @words[category][word.stem].to_f + 1 / @categories_words[category].to_f
    end

    def category_probability(category)
        @categories_documents[category].to_f/@total_documents.to_f
    end

    def classify(document, default='unknown')
        sorted = probabilities(document).sort {|a,b| a[1] <=> b[1]}
        best,second_best = sorted.pop, sorted.pop
        return best[0] if (best[1]/second_best[1] > @threshold)
    end

    def word_count(document)
        words = document.gsub(/[^\w\s]/, "").split
        d = Hash.new
        words.each do |word|
            word.downcase!
            key = word.stem
            unless @common_words.include?(word)
                d[key] ||=0
                d[key] += 1
            end
        end
        return d
    end
    
    def probabilities(document)
        probabilities = Hash.new
        @words.each_key do |category|
            probabilities[category] = probability(category, document)
        end
        return probabilities
    end

    def probability(category, document)
        doc_probability(category, document) * category_probability(category)
    end

    def doc_probability(category, document)
        doc_prob = 1
        word_count(document).each do |word|
            doc_prob *= word_probability(category, word[0])
        end
        return doc_prob
    end
end
