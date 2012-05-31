class ArticlesController < ApplicationController
  before_filter :require_admin_user

  # GET /articles
  # GET /articles.xml
  def index
    @title = t('view.articles.index_title')
    @articles = Article.order("#{Article.table_name}.name ASC").paginate(
      page: params[:page], per_page: lines_per_page
    )

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render xml: @articles }
    end
  end

  # GET /articles/1
  # GET /articles/1.xml
  def show
    @title = t('view.articles.show_title')
    @article = Article.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render xml: @article }
    end
  end

  # GET /articles/new
  # GET /articles/new.xml
  def new
    @title = t('view.articles.new_title')
    @article = Article.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render xml: @article }
    end
  end

  # GET /articles/1/edit
  def edit
    @title = t('view.articles.edit_title')
    @article = Article.find(params[:id])
  end

  # POST /articles
  # POST /articles.xml
  def create
    @title = t('view.articles.new_title')
    @article = Article.new(params[:article])

    respond_to do |format|
      if @article.save
        format.html { redirect_to(articles_url, notice: t('view.articles.correctly_created')) }
        format.xml  { render xml: @article, status: :created, location: @article }
      else
        format.html { render action: 'new' }
        format.xml  { render xml: @article.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /articles/1
  # PUT /articles/1.xml
  def update
    @title = t('view.articles.edit_title')
    @article = Article.find(params[:id])

    respond_to do |format|
      if @article.update_attributes(params[:article])
        format.html { redirect_to(articles_url, notice: t('view.articles.correctly_updated')) }
        format.xml  { head :ok }
      else
        format.html { render action: 'edit' }
        format.xml  { render xml: @article.errors, status: :unprocessable_entity }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t('view.articles.stale_object_error')
    redirect_to edit_article_url(@article)
  end

  # DELETE /articles/1
  # DELETE /articles/1.xml
  def destroy
    @article = Article.find(params[:id])
    @article.destroy

    respond_to do |format|
      format.html { redirect_to(articles_url) }
      format.xml  { head :ok }
    end
  end
end