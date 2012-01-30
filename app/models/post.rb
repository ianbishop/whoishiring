class Post
  include MongoMapper::Document
  include Gmaps4rails::ActsAsGmappable

  key :company, String
  key :author, String
  key :content, String
  key :location, String
  key :position, String
  key :create_ts, String
  key :intern, Boolean
  key :remote, Boolean
  key :honeb, Boolean
  key :latitude, Float
  key :longitude, Float
  key :address, String
  key :gmaps, Boolean
  key :emails, Array
  key :urls, Array
  timestamps!

  acts_as_gmappable :lat => 'latitude', :lon => 'longitude', :process_geocoding => true,
                    :check_process => :prevent_geocoding,
                    :address => 'address', :normalized_address => 'address'

  def prevent_geocoding
    address.blank? || (!lat.blank? && !lon.blank?)
  end

  def gmaps4rails_address
      "#{self.company}, #{self.location}"
  end
end
