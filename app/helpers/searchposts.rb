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
      content = item[:text]
      document = content.downcase

      if @classifier.classify(document) == 'hiring'
        user_post = Post.where({:author => item[:username]}).first
        
        if user_post.nil? or item[:create_ts] > user_post.create_ts
          
          post = Post.new
          post.content = content
          post.author = item[:username]
          post.intern = (document.include? "intern")
          post.remote = (document.include? "remote")
          post.honeb = (document.include? "h1b")
          post.create_ts = item[:create_ts]
          post.save(:validate => false)

          user_post.destroy unless user_post.nil?
        end
      end
    end
  end

end
