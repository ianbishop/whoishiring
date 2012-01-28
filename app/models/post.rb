class Post
  include MongoMapper::Document

  key :company, String
  key :author, String
  key :content, String
  key :location, String
  key :intern, Boolean
  key :remote, Boolean
  key :full_time, Boolean
  key :latitude, Float
  key :longitude, Float
  key :gmaps, Boolean
  key :emails, Array
  key :urls, Array

end
