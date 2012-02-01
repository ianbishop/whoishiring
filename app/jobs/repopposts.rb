require 'searchposts'

updater = UpdatePosts.new
Post.all.each do |post|
  updater.populate_urls(post)
  updater.parse_emails(post)
  updater.parse_company(post)
  updater.parse_technologies(post)
  updater.parse_cities(post)
  updater.add_tags(post)
end
