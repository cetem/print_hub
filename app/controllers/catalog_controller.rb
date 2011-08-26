class CatalogController < ApplicationController
  before_filter :require_customer, :load_documents_to_order, :load_tag
  
  layout lambda { |controller| controller.request.xhr? ? false : 'application' }
  
  def index
    @title = t :'view.catalog.index_title'
    
    if params[:q].present? || @tag
      query = params[:q].try(:sanitized_for_text_query) || ''
      @query_terms = query.split(/\s+/).reject(&:blank?)
      @documents = document_scope
      
      unless @query_terms.empty?
        parameters = {
          :and_term => @query_terms.join(' & '),
          :wilcard_term => "%#{@query_terms.join('%')}%".downcase
        }

        if DB_ADAPTER == 'PostgreSQL'
          pg_query = pg_text_query('name', 'tag_path')
          query, order = pg_query[:query], pg_query[:order]

          order = Document.send(:sanitize_sql_for_conditions, [order, parameters])
        else
          query = simple_text_query('name', 'tag_path')
          order = 'name ASC'
        end
        
        conditions = [query]

        @query_terms.each_with_index do |term, i|
          if term =~ /^\d+$/ # Sólo si es un número vale la pena la condición
            conditions << "#{Document.table_name}.code = :clean_term_#{i}"
            parameters[:"clean_term_#{i}"] = term.to_i
          end
        end

        @documents = @documents.where(
          conditions.map { |c| "(#{c})" }.join(' OR '), parameters
        )
      end
      
      @documents = @documents.order("#{Document.table_name}.code ASC").paginate(
        :page => params[:page],
        :per_page => (APP_LINES_PER_PAGE / 2).round
      )
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @documents }
    end
  end

  def show
    @title = t :'view.catalog.show_title'
    @document = document_scope.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @document }
    end
  end
  
  # GET /catalog/1/pdf_thumb/download
  def download
    @document = document_scope.find(params[:id])
    style = params[:style].try(:to_sym)
    styles = [
      :pdf_thumb, :pdf_thumb_2, :pdf_thumb_3,
      :pdf_mini_thumb, :pdf_mini_thumb_2, :pdf_mini_thumb_3
    ]
    file = @document.file.path(style)

    if styles.include?(style) && File.exists?(file)
      mime_type = Mime::Type.lookup_by_extension(File.extname(file)[1..-1])
      
      response.headers['Last-Modified'] = File.mtime(file).httpdate
      response.headers['Cache-Control'] = 'private, no-store'

      send_file file, :type => (mime_type || 'application/octet-stream')
    else
      redirect_to catalog_url, :notice => t(:'view.documents.non_existent')
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
end
