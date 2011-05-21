class PrintsController < ApplicationController
  before_filter :require_user, :load_customer

  layout proc { |controller| controller.request.xhr? ? false : 'application' }

  # GET /prints
  # GET /prints.xml
  def index
    @title = t :'view.prints.index_title'
    order = params[:status] == 'scheduled' ? 'scheduled_at ASC' :
      'created_at DESC'
    
    @prints = prints_scope.order(order).paginate(
      :page => params[:page],
      :per_page => APP_LINES_PER_PAGE
    )

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @prints }
    end
  end

  # GET /prints/1
  # GET /prints/1.xml
  def show
    @title = t :'view.prints.show_title'
    @print = prints_scope.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @print }
    end
  end

  # GET /prints/new
  # GET /prints/new.xml
  def new
    @title = t :'view.prints.new_title'
    @print = current_user.prints.build(
      :include_documents => session[:documents_for_printing]
    )

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @print }
    end
  end

  # GET /prints/1/edit
  def edit
    @title = t :'view.prints.edit_title'
    @print = prints_scope.find(params[:id])

    if !@print.pending_payment && !@print.scheduled?
      raise 'This print is readonly!'
    end
  end

  # POST /prints
  # POST /prints.xml
  def create
    @title = t :'view.prints.new_title'
    @print = current_user.prints.build(params[:print])
    session[:documents_for_printing].try(:clear)

    respond_to do |format|
      if @print.save
        format.html { redirect_to(@print, :notice => t(:'view.prints.correctly_created')) }
        format.xml  { render :xml => @print, :status => :created, :location => @print }
      else
        format.html { render :action => :new }
        format.xml  { render :xml => @print.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /prints/1
  # PUT /prints/1.xml
  def update
    @title = t :'view.prints.edit_title'
    @print = prints_scope.find(params[:id])

    if !@print.pending_payment && !@print.scheduled?
      raise 'This print is readonly!'
    end

    respond_to do |format|
      if @print.update_attributes(params[:print])
        format.html { redirect_to(@print, :notice => t(:'view.prints.correctly_updated')) }
        format.xml  { head :ok }
      else
        format.html { render :action => :edit }
        format.xml  { render :xml => @print.errors, :status => :unprocessable_entity }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t :'view.prints.stale_object_error'
    redirect_to edit_print_url(@print)
  end

  # GET /prints/autocomplete_for_document_name
  def autocomplete_for_document_name
    query = params[:q].strip.gsub(/\s*([&|])\s*/, '\1').gsub(/[|&!]$/, '')
    @query_terms = query.split(/\s+/).reject(&:blank?)
    @docs = Document.scoped

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

      @docs = @docs.where(
        conditions.map { |c| "(#{c})" }.join(' OR '), parameters
      ).order(order)
    end

    @docs = @docs.limit(10)
  end

  # GET /prints/autocomplete_for_article_name
  def autocomplete_for_article_name
    query = params[:q].strip.gsub(/\s*([&|])\s*/, '\1').gsub(/[|&!]$/, '')
    @query_terms = query.split(/\s+/).reject(&:blank?)
    @articles = Article.scoped

    unless @query_terms.empty?
      parameters = {
        :and_term => @query_terms.join(' & '),
        :wilcard_term => "%#{@query_terms.join('%')}%"
      }

      if DB_ADAPTER == 'PostgreSQL'
        lang = "'spanish'" # TODO: implementar con I18n
        query = "to_tsvector(#{lang}, name) @@ to_tsquery(#{lang}, :and_term)"
        order = "ts_rank_cd(#{query.sub(' @@', ',')})"

        order = Article.send(:sanitize_sql_for_conditions, [order, parameters])
      else
        query = "LOWER(name) LIKE LOWER(:wilcard_term)"
        order = 'name ASC'
      end
      conditions = [query]

      @query_terms.each_with_index do |term, i|
        if term =~ /^\d+$/ # Sólo si es un número vale la pena la condición
          conditions << "#{Article.table_name}.code = :clean_term_#{i}"
          parameters[:"clean_term_#{i}"] = term.to_i
        end
      end

      @articles = @articles.where(
        conditions.map { |c| "(#{c})" }.join(' OR '), parameters
      ).order(order)
    end

    @articles = @articles.limit(10)
  end
  
  # GET /prints/autocomplete_for_customer_name
  def autocomplete_for_customer_name
    query = params[:q].strip.gsub(/\s*([&|])\s*/, '\1').gsub(/[|&!]$/, '')
    @query_terms = query.split(/\s+/).reject(&:blank?)
    @customers = Customer.scoped

    unless @query_terms.empty?
      parameters = {
        :and_term => @query_terms.join(' & '),
        :wilcard_term => "%#{@query_terms.join('%')}%"
      }

      if DB_ADAPTER == 'PostgreSQL'
        lang = "'spanish'" # TODO: implementar con I18n
        query = "to_tsvector(#{lang}, coalesce(identification,'') || ' ' || coalesce(name,'') || ' ' || coalesce(lastname,'')) @@ to_tsquery(#{lang}, :and_term)"
        order = "ts_rank_cd(#{query.sub(' @@', ',')})"

        order = Customer.send(:sanitize_sql_for_conditions, [order, parameters])
      else
        query = [
          "LOWER(name) LIKE LOWER(:wilcard_term)",
          "LOWER(lastname) LIKE LOWER(:wilcard_term)",
          "LOWER(identification) LIKE LOWER(:wilcard_term)"
        ].join(' OR ')
        order = 'name ASC'
      end
      conditions = [query]

      @customers = @customers.where(
        conditions.map { |c| "(#{c})" }.join(' OR '), parameters
      ).order(order)
    end

    @customers = @customers.limit(10)
  end

  # PUT /prints/cancel_job
  def cancel_job
    @print_job = PrintJob.find(params[:id])
    @cancelled = @print_job.cancel
  end

  private
  
  def load_customer
    @customer = Customer.find(params[:customer_id]) if params[:customer_id]
  end

  def prints_scope
    if @customer
      scope = @customer.prints
    else
      scope = current_user.admin ? Print.scoped : current_user.prints
    end

    case params[:status]
      when 'pending'
        scope = scope.pending
      when 'scheduled'
        scope = scope.scheduled
    end

    scope
  end
end