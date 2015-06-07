class CatalogController < ApplicationController
  before_filter :require_customer, :load_documents_to_order, :load_tag, :load_parent
  helper_method :sort_column, :sort_direction

  layout ->(controller) { controller.request.xhr? ? false : 'application' }

  def index
    @title = t('view.catalog.index_title')
    @searchable = true

    if params[:q].present? || @tag
      query = params[:q].try(:sanitized_for_text_query) || ''
      @query_terms = query.split(/\s+/).reject(&:blank?)
      @documents = document_scope
      @documents = @documents.full_text(@query_terms) unless @query_terms.empty?

      @documents = @documents.order(
        "#{Document.table_name}.#{sort_column} #{sort_direction.upcase}"
      ).paginate(page: params[:page], per_page: (APP_LINES_PER_PAGE / 2).round)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json  { render json: @documents }
    end
  end

  def show
    @title = t('view.catalog.show_title')
    @document = document_scope.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json  { render json: @document }
    end
  end

  # POST /catalog/1/add_to_order
  def add_to_order
    @document = document_scope.find(params[:id])
    session[:documents_to_order] ||= []

    unless session[:documents_to_order].include?(@document.id)
      session[:documents_to_order] << @document.id
    end
  end

  # DELETE /catalog/1/remove_from_order
  def remove_from_order
    @document = document_scope.find(params[:id])
    session[:documents_to_order] ||= []

    session[:documents_to_order].delete(@document.id)
  end

  # GET /catalog/1/add_to_order_by_code
  def add_to_order_by_code
    @document = document_scope.find_by_code(params[:id])

    if @document
      session[:documents_to_order] ||= []

      unless session[:documents_to_order].include?(@document.id)
        session[:documents_to_order] << @document.id
      end

      redirect_to new_order_url
    else
      redirect_to catalog_url, notice: t('view.documents.non_existent')
    end
  end

  # GET /catalog/tags
  def tags
    @title = t('view.tags.index_title')
    @tags = @parent.try(:children) || Tag.publicly_visible
    @tags = @tags.where('parent_id IS NULL') unless @parent
    @tags = @tags.order(
      "#{Tag.table_name}.name ASC"
    ).with_documents_or_children.paginate(
      page: params[:page], per_page: (APP_LINES_PER_PAGE / 2).round
    )

    respond_to do |format|
      format.html # index.html.erb
      format.json  { render json: @tags }
    end
  end

  private

  def load_documents_to_order
    session[:documents_to_order] ||= []
    @documents_to_order = session[:documents_to_order]
  end

  def load_tag
    @tag = Tag.publicly_visible.find(params[:tag_id]) if params[:tag_id]
  end

  def document_scope
    @tag ? @tag.documents.publicly_visible : Document.publicly_visible
  end

  def load_parent
    @parent = Tag.publicly_visible.find(params[:parent_id]) if params[:parent_id]
  end

  def sort_column
    %w(code name).include?(params[:sort]) ? params[:sort] : 'code'
  end

  def sort_direction
    %w(asc desc).include?(params[:direction]) ?
      params[:direction] : default_direction
  end

  def default_direction
    sort_column == 'code' ? 'desc' : 'asc'
  end
end
