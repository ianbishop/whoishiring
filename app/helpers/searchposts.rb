require 'naiveclassifier'
require 'uri'

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

  def update_posts
    #Get the newest batch of posts, start with the most recent id
  end
  def edit_distance
    
  end

  def get_posts(id)
    query = @client.search("items", "", { "filter[fields][parent_sigid][]" => id, :limit => "100"} )
    query[:results].each do |result|
      item = result[:item]
     
      #feed it to the classifier
      document = item[:text].downcase

      if @classifier.classify(document) == 'hiring'
        user_post = Post.where({:author => item[:username]}).first
        
        if user_post.nil? or item[:create_ts] > user_post.create_ts
                
          post = Post.new
          post.content = item[:text]
          post.author = item[:username]
          post.intern = (document.include? "intern")
          post.remote = (document.include? "remote")
          post.honeb = (document.include? "h1b")

          document.split.each do |word|
            post.emails << word if /\w*@\w*\.\w*/.match(word)
          end
          
          #Get urls
          doc = Nokogiri::HTML(item[:text])
          doc.css('a').each do |url|
            post.urls << url[:href]
          end
         
          #Get technologies from content
          techs = File.open('lib/files/languages.txt').readlines.map! do |e| e=e.chop end
          techs.each do |tech|
            if document.include? tech.downcase
              post.technologies << tech
            end
          end

          # company name, this gonna be dirty.
          

          post.create_ts = item[:create_ts]
          post.save(:validate => false)

          user_post.destroy unless user_post.nil?
        end
      end
    end
  end

end
