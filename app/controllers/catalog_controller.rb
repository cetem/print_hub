class CatalogController < ApplicationController
  before_filter :require_customer
  
  def index
    @title = t :'view.catalog.index_title'
    @tag = Tag.find(params[:tag_id]) if params[:tag_id]
    @documents = @tag ? @tag.documents : Document.scoped

    if params[:q]
      query = params[:q].strip.gsub(/\s*([&|])\s*/, '\1').gsub(/[|&!]$/, '')
      @query_terms = query.split(/\s+/).reject(&:blank?)

      unless @query_terms.empty?
        parameters = {
          :and_term => @query_terms.join(' & '),
          :wilcard_term => "%#{@query_terms.join('%')}%"
        }

        if DB_ADAPTER == 'PostgreSQL'
          lang = "'spanish'" # TODO: implementar con I18n
          query = "to_tsvector(#{lang}, coalesce(name,'') || ' ' || coalesce(tag_path,'')) @@ to_tsquery(#{lang}, :and_term)"
          order = "ts_rank_cd(#{query.sub(' @@', ',')})"

          order = Document.send(:sanitize_sql_for_conditions, [order, parameters])
        else
          query = "LOWER(name) LIKE LOWER(:wilcard_term) OR LOWER(tag_path) LIKE LOWER(:wilcard_term)"
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
    end

    @documents = @documents.order("#{Document.table_name}.code ASC").paginate(
      :page => params[:page],
      :per_page => APP_LINES_PER_PAGE
    )

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @documents }
    end
  end

  def show
    @title = t :'view.catalog.show_title'
    @document = Document.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @document }
    end
  end
  
  # GET /catalog/1/pdf_thumb/download
  def download
    @document = Document.find(params[:id])
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
end