require 'naiveclassifier'

class UpdatePosts
  def initialize
    @client = HackerNewsSearch.new
    @classifier = Classifier.new
    @classifier.train("hiring", "app/helpers/whoishiring.txt")
    @classifier.train("not hiring", "app/helpers/whoisnothiring.txt")
  end

  def get_hiring_ids(limit)
    ids = []

    query = @client.search("items", "Ask HN: Who is Hiring?",
                         { "filter[fields][username][]" => "whoishiring",
                           :limit => limit,
                           :sortby => "create_ts desc"} )
    
    query[:results].each do |result|
      id = result[:item][:_id]
      ids << id
    end
    ids
  end

  def get_posts(id)
    query = @client.search("items", "", { "filter[fields][parent_sigid][]" => id, :limit => "100"} )
    query[:results].each do |result|
      item = result[:item]
     
      #feed it to the classifier
      document = item[:text].downcase
      document = document.gsub(/<.*>.*<\/.*>/, '').gsub(/<.*>/,'').gsub(/[\.\'\"\;\!\:\(\)\-\{\}]/,'')
      if @classifier.classify(document) == 'hiring'
        post = Post.new
        post.content = item[:text]
        post.author = item[:username]
        post.save!
      end
    end
  end

end
