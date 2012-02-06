class PostsController < ApplicationController
  # GET /posts
  # GET /posts.json
  def index
    #Process searches and filters
    filters = {}
    #Filter posts by tag and company
    params.each do |parameter|
      if parameter == nil
        continue
      end
      if parameter == ['honeb', 'true']
        filters[:honeb] = true
      elsif parameter == ['remote', 'true']
        filters[:remote] = true
      elsif parameter == ['intern', 'true']
        filters[:intern] = true
      elsif parameter[0] == 'company'
        filters[:company] = {:$regex => /#{parameter[1]}/i}
      end 
    end

    @posts = Post.where(filters).sort(:created.desc)

    #Filter posts by position, technology, location
    unless params[:position].nil?
      @posts = @posts.where(:positions => {:$regex => /#{params[:position]}/i})
    end

    unless params[:technologies].nil?
      searches = {}
      or_criteria = []
      params[:technologies].split(',').each do |searchstr|
        or_criteria << {:technologies => {:$regex => /\b#{searchstr.strip}\b/i}}
      end
      searches[:$or] = or_criteria
      #@posts = @posts.where(:technologies => {:$regex => /#{params[:technologies]}/i})
      @posts = @posts.where(:technologies => {:$regex => /#{params[:technologies]}/i})
    end

    unless params[:location].nil?
      @posts = @posts.where(:location => {:$regex => /#{params[:location]}/i})
    end

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
