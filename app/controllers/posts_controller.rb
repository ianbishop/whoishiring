class PostsController < ApplicationController
  # GET /posts
  # GET /posts.json
  def index
    #Process searches and filters
    filters = {}
    logger.info params
    params.each do |parameter|
      logger.info parameter
      if parameter == ['honeb', 'true']
        filters[:honeb] = true
      elsif parameter == ['remote', 'true']
        filters[:remote] = true
      elsif parameter == ['intern', 'true']
        filters[:intern] = true
      end 
    end

    @posts = Post.where(filters).sort(:created.desc)
    
    @posts = @posts.page(params[:page]).per(20)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @posts }
    end
  end

  # GET /posts/1
  # GET /posts/1.json
  def show
    @post = Post.where(:id => params[:id]).first

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @post }
    end
  end

end
