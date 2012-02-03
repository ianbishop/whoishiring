require 'utils/classifier'
require 'uri'
require 'parsers/company'
require 'parsers/city'
require 'parsers/positions'
require 'date'

class SearchPosts
  def initialize
    @client = HackerNewsSearch.new
    @classifier = Classifier.new
    @classifier.train("hiring", "lib/files/whoishiring.txt")
    @classifier.train("not hiring", "lib/files/whoisnothiring.txt")
    @company_parser = Company.new(@classifier)
    @cityparser = City.new
    @positionparser = Positions.new
  end

  def get_ids(limit)
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

  def parse_positions(post)
   document = post[:content]
   post.positions = @positionparser.match(document)
   post.save(:validate => false) 
  end

  def parse_cities(post)
    #Here we'll try and pull cities from a post
    document = post[:content]
    post.location = @cityparser.match_document(document)
    post.save(:validate => false)
  end

  def parse_emails(post)
    #Try to get a little more sophisticated with the e-mail parser. Regular and obfuscated emails.
    #Also obfuscate regular e-mails
    document = post[:content]

    post.emails = []
    #Get rid of html tag issues
    document = document.gsub(/\<p\>/, ' ')
    #How about weirder obfuscation?
    document = document.gsub(/ *[\[\{\<] *a *t *[\]\}\>] */, '@')
    document = document.gsub(/ *[\[\{\<] *dot *[\]\}\>] */, '.')

    #What about that case where people run all their stuff together and it's like mikeATwhateverDOTcom?
    document = document.gsub(/([a-z0-9])at([a-z0-9])dot([a-z0-9])/, '<\1>@<\2>.<\3>')

    #Lets take a look at regular e-mails and obfuscate them.
    document = document.gsub(/\<p\>/, ' ')
    document.split(' ').each do |word|
      email_to_uglify = word if /\w*@\w*\.\w*/.match(word)
      if !email_to_uglify.nil?
        # moving this to a helper so that i can parse urls from the emails!
        #email_to_uglify = email_to_uglify.gsub(/\./, ' [ dot ] ').gsub(/@/, ' [ at ] ') 
        post.emails << email_to_uglify
      end
    end

    post.save(:validate => false)
  end

  def populate_urls(post)
    #Get urls
    post.urls = []
    document = post[:content]
    doc = Nokogiri::HTML(document)
    doc.css('a').each do |url|
      safe_url = url[:href].gsub(/<\/?[^>]*>/, "")
      post.urls << safe_url
    end
    
    # grab urls from email on the off chance they didn't post a url
    post.emails.each do |email|
      host = email.split("@")[1]
      post.urls << ("http://www." + host) unless host.nil?
    end

    post.save(:validate => false)
  end

  def add_tags(post)
    document = post[:content]
    post.intern = (document.include? "intern")
    post.remote = (document.include? "remote")
    post.honeb = (document.include? "h1b")
    post.save(:validate => false)
  end

  def parse_company(post)
    document = post[:content]
    post.company = @company_parser.parse(document, post.urls)
    post.save(:validate => false)
  end

  def parse_technologies(post)
    post.technologies = []
    document = post[:content].downcase
    #Get technologies from content
    techs = File.open('lib/files/languages.txt').readlines.map! do |e| e=e.chop end
    techs.each do |tech|
      if document.include? tech.downcase
        post.technologies << tech
      end
    end
  end

  def get_posts(id)
    query = @client.search("items", "", { "filter[fields][parent_sigid][]" => id, :limit => "100"} )
    query[:results].each do |result|
      item = result[:item]
     
      #feed it to the classifier
      document = item[:text].downcase

      if @classifier.classify(document) == 'hiring'
        user_post = Post.where({:author => item[:username]}).first
        
        #2012-01-01T15:00:54Z
        created = Date.strptime(item[:create_ts], "%Y-%m-%d").to_time

        if user_post.nil? or created > user_post.created
                
          post = Post.new
          post.content = item[:text]
          post.author = item[:username]
          post.created = created
          
          post.save(:validate => false)

          user_post.destroy unless user_post.nil?
        end
      end
    end
  end
end
