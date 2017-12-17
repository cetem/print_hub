class TagsController < ApplicationController
  before_action :require_admin_user, except: [:show, :index]
  before_action :require_user, only: [:show, :index]
  before_action :load_parent

  # GET /tags
  # GET /tags.json
  def index
    @title = t('view.tags.index_title')
    @searchable = true
    @tags = @parent_tag.try(:children) || Tag
    @tags = @tags.where('parent_id IS NULL') unless @parent_tag
    @tags = @tags.order("#{Tag.table_name}.name ASC").paginate(
      page: params[:page], per_page: lines_per_page
    )

    respond_to do |format|
      format.html # index.html.erb
      format.json  { render json: @tags }
    end
  end

  # GET /tags/1
  # GET /tags/1.json
  def show
    @title = t('view.tags.show_title')
    @tag = Tag.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json  { render json: @tag }
    end
  end

  # GET /tags/new
  # GET /tags/new.json
  def new
    @title = t('view.tags.new_title')
    @tag = Tag.new(parent_id: params[:parent])

    respond_to do |format|
      format.html # new.html.erb
      format.json  { render json: @tag }
    end
  end

  # GET /tags/1/edit
  def edit
    @title = t('view.tags.edit_title')
    @tag = Tag.find(params[:id])
  end

  # POST /tags
  # POST /tags.json
  def create
    @title = t('view.tags.new_title')
    @tag = Tag.new(tag_params)

    respond_to do |format|
      if @tag.save
        format.html { redirect_to(tags_url(parent: @tag.parent), notice: t('view.tags.correctly_created')) }
        format.json  { render json: @tag, status: :created, location: @tag }
      else
        format.html { render action: 'new' }
        format.json  { render json: @tag.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /tags/1
  # PUT /tags/1.json
  def update
    @title = t('view.tags.edit_title')
    @tag = Tag.find(params[:id])

    respond_to do |format|
      if @tag.update(tag_params)
        format.html { redirect_to(tags_url(parent: @tag.parent), notice: t('view.tags.correctly_updated')) }
        format.json  { head :ok }
      else
        format.html { render action: 'edit' }
        format.json  { render json: @tag.errors, status: :unprocessable_entity }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t('view.tags.stale_object_error')
    redirect_to edit_tag_url(@tag)
  end

  # DELETE /tags/1
  # DELETE /tags/1.json
  def destroy
    @tag = Tag.find(params[:id])
    @tag.destroy

    respond_to do |format|
      format.html { redirect_to(tags_url(parent: @parent_tag)) }
      format.json  { head :ok }
    end
  end

  private

  def load_parent
    @parent_tag = Tag.find(params[:parent]) if params[:parent]
  end

  def tag_params
    params.require(:tag).permit(:name, :parent_id, :private, :lock_version)
  end
end
