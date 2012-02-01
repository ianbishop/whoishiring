require 'searchposts'

updater = UpdatePosts.new
Post.destroy_all
updater.get_ids(5).each do |id|
  updater.get_posts(id)
end
