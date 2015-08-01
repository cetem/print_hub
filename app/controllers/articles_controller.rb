class ArticlesController < ApplicationController
  before_action :require_admin_user

  # GET /articles
  # GET /articles.json
  def index
    @title = t('view.articles.index_title')
    @searchable = true
    @articles = Article.all

    if params[:q].present?
      query = params[:q].sanitized_for_text_query
      query_terms = query.split(/\s+/).reject(&:blank?)
      @articles = @articles.full_text(query_terms) unless query_terms.empty?
    end

    _order = if (_order = params[:order]).present?
               _order.map {|k, v| "#{k} #{v}"}.join(',')
             else
               { code: :desc }
             end

    @articles = @articles.order(_order).paginate(
      page: params[:page], per_page: lines_per_page
    )

    respond_to do |format|
      format.html # index.html.erb
      format.json  { render json: @articles }
    end
  end

  # GET /articles/1
  # GET /articles/1.json
  def show
    @title = t('view.articles.show_title')
    @article = Article.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json  { render json: @article }
    end
  end

  # GET /articles/new
  # GET /articles/new.json
  def new
    @title = t('view.articles.new_title')
    @article = Article.new

    respond_to do |format|
      format.html # new.html.erb
      format.json  { render json: @article }
    end
  end

  # GET /articles/1/edit
  def edit
    @title = t('view.articles.edit_title')
    @article = Article.find(params[:id])
  end

  # POST /articles
  # POST /articles.json
  def create
    @title = t('view.articles.new_title')
    @article = Article.new(article_params)

    respond_to do |format|
      if @article.save
        format.html { redirect_to(articles_url, notice: t('view.articles.correctly_created')) }
        format.json  { render json: @article, status: :created, location: @article }
      else
        format.html { render action: 'new' }
        format.json  { render json: @article.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /articles/1
  # PUT /articles/1.json
  def update
    @title = t('view.articles.edit_title')
    @article = Article.find(params[:id])

    respond_to do |format|
      if @article.update_attributes(article_params)
        format.html { redirect_to(articles_url, notice: t('view.articles.correctly_updated')) }
        format.json  { head :ok }
      else
        format.html { render action: 'edit' }
        format.json  { render json: @article.errors, status: :unprocessable_entity }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t('view.articles.stale_object_error')
    redirect_to edit_article_url(@article)
  end

  # DELETE /articles/1
  # DELETE /articles/1.json
  def destroy
    @article = Article.find(params[:id])
    @article.destroy

    respond_to do |format|
      format.html { redirect_to(articles_url) }
      format.json  { head :ok }
    end
  end

  private

  # Atributos permitidos
  def article_params
    params.require(:article).permit(
      :name, :code, :price, :description, :lock_version, :stock
    )
  end
end
