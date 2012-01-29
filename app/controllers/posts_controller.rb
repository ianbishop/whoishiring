class PostsController < ApplicationController
  # GET /posts
  # GET /posts.json
  def index
    @posts = Post.sort(:author).page(params[:page]).per(20)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @posts }
    end
  end

  # GET /posts/1
  # GET /posts/1.json
  def show
    @post = Post.where(:id => params[:id]).first
    @prev_page = params[:page]
    @json = @post.to_gmaps4rails

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @post }
    end
  end

end
