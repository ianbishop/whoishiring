require 'naiveclassifier'
require 'uri'
require 'company_parser'
require 'cities'

class UpdatePosts
  def initialize
    @client = HackerNewsSearch.new
    @classifier = Classifier.new
    @company_parser = CompanyParser.new
    @classifier.train("hiring", "app/helpers/whoishiring.txt")
    @classifier.train("not hiring", "app/helpers/whoisnothiring.txt")
    @cityparser = Cities.new
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

  def update_posts
    #Get the newest batch of posts, start with the most recent id
  end

  def parse_emails(document)
    #Try to get a little more sophisticated with the e-mail parser. Regular and obfuscated emails.
    #Also obfuscate regular e-mails
    emails = []
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
        email_to_uglify = email_to_uglify.gsub(/\./, ' [ dot ] ').gsub(/@/, ' [ at ] ') 
        emails << email_to_uglify
      end
    end
    
    emails
  end

  def populate_urls(post)
    #Get urls
    document = post[:content]
    doc = Nokogiri::HTML(document])
    doc.css('a').each do |url|
      safe_url = url[:href].gsub(/<\/?[^>]*>/, "")
      post.urls << safe_url
    end
    post.save(:validate => false)
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
          post.location = @cityparser.parse_cities(document)

          post.emails = parse_emails(document) 
          
         
          post.company = @company_parser.parse(item[:text], post.urls)
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
