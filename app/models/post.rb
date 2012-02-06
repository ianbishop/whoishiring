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

  def pretty_position_company
    position_company = ""
    if self.positions.length > 0 and !self.company.nil?
      position_company = "#{self.pretty_positions} at #{self.company}"
    elsif self.positions.length > 0
      position_company = self.pretty_positions.to_s
    elsif !self.company.nil?
      position_company = self.company.to_s
    end
    return position_company
  end
end
