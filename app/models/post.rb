class Post
  include MongoMapper::Document

  key :company, String
  key :author, String
  key :content, String
  key :location, String
  key :positions, Array 
  key :created, Time
  key :intern, Boolean
  key :remote, Boolean
  key :honeb, Boolean
  key :emails, Array
  key :urls, Array
  key :technologies, Array
  timestamps!

  def pretty_created
    self.created.strftime("%B %e, %Y")
  end

  def pretty_positions
    self.positions.join("/")
  end

  def pretty_technologies
    self.technologies.join("/")
  end

  def pretty_emails
    return self.emails.map do |email|
      email = email.gsub(/\./, ' [ dot ] ').gsub(/@/, ' [ at ] ')
    end
  end
end
