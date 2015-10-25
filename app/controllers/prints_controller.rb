class PrintsController < ApplicationController
  before_action :require_customer_or_user, except: [:revoke, :related_by_customer]
  before_action :require_admin_user, only: [:revoke, :related_by_customer]
  before_action :load_customer

  layout ->(controller) { controller.request.xhr? ? false : 'application' }

  # GET /prints
  # GET /prints.json
  def index
    @title = t('view.prints.index_title')
    order = params[:status] == 'scheduled' ? 'scheduled_at ASC' :
      'created_at DESC'

    @prints = prints_scope.order(order).paginate(
      page: params[:page], per_page: lines_per_page
    )

    respond_to do |format|
      format.html # index.html.erb
      format.json  { render json: @prints }
    end
  end

  # GET /prints/1
  # GET /prints/1.json
  def show
    @title = t('view.prints.show_title')
    @print = prints_scope.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json  { render json: @print }
    end
  end

  # GET /prints/new
  # GET /prints/new.json
  def new
    @title = t('view.prints.new_title')

    unless params[:clear_documents_for_printing].blank?
      session[:documents_for_printing].try(:clear)
    end

    @print = current_user.prints.build(
      order_id: params[:order_id],
      include_documents: session[:documents_for_printing]
    )

    respond_to do |format|
      format.html # new.html.erb
      format.json  { render json: @print }
    end
  end

  # GET /prints/1/edit
  def edit
    @title = t('view.prints.edit_title')
    @print = prints_scope.find(params[:id])

    if !@print.pending_payment? && !@print.scheduled?
      fail 'This print is readonly!'
    end
  end

  # POST /prints
  # POST /prints.json
  def create
    @title = t('view.prints.new_title')
    @print = current_user.prints.build(print_params)
    session[:documents_for_printing].try(:clear)

    respond_to do |format|
      if @print.save
        format.html { redirect_to(@print, notice: t('view.prints.correctly_created')) }
        format.json  { render json: @print, status: :created, location: @print }
      else
        report_validation_error(@print) unless @print.errors[:credit_password].present?
        format.html { render action: 'new' }
        format.json  { render json: @print.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /prints/1
  # PUT /prints/1.json
  def update
    @title = t('view.prints.edit_title')
    @print = prints_scope.find(params[:id])

    if !@print.pending_payment? && !@print.scheduled?
      fail 'This print is readonly!'
    end

    respond_to do |format|
      if @print.update_attributes(print_params)
        format.html { redirect_to(@print, notice: t('view.prints.correctly_updated')) }
        format.json  { head :ok }
      else
        report_validation_error(@print) unless @print.errors[:credit_password].present?
        format.html { render action: 'edit' }
        format.json  { render json: @print.errors, status: :unprocessable_entity }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t('view.prints.stale_object_error')
    redirect_to edit_print_url(@print)
  end

  # DELETE /prints/1/revoke
  # DELETE /prints/1/revoke.json
  def revoke
    @print = prints_scope.find(params[:id])
    @print.revoke!

    respond_to do |format|
      format.html { redirect_to(prints_url, notice: t('view.prints.correctly_revoked')) }
      format.json  { head :ok }
    end
  end

  # POST /prints/upload_file
  def upload_file
    @print = Print.new
    file_line = FileLine.create(file_line_params)
    @print.print_jobs.build(file_line.attributes.slice('id'))

    respond_to do |format|
      if file_line
        format.html { render partial: 'file_print_job' }
        format.js
      else
        format.html { head :unprocessable_entity }
        format.js { head :unprocessable_entity }
      end
    end
  end

  # GET /prints/autocomplete_for_document_name
  def autocomplete_for_document_name
    query = params[:q].sanitized_for_text_query
    @query_terms = query.split(/\s+/).reject(&:blank?)
    @docs = Document.all
    @docs = @docs.full_text(@query_terms) unless @query_terms.empty?
    @docs = @docs.limit(10)

    respond_to do |format|
      format.json { render json: @docs }
    end
  end

  # GET /prints/autocomplete_for_article_name
  def autocomplete_for_article_name
    query = params[:q].sanitized_for_text_query
    query_terms = query.split(/\s+/).reject(&:blank?)
    articles = Article.all
    articles = articles.full_text(query_terms) unless query_terms.empty?
    articles = articles.limit(10)

    respond_to do |format|
      format.json { render json: articles }
    end
  end

  # GET /prints/autocomplete_for_customer_name
  def autocomplete_for_customer_name
    query = params[:q].sanitized_for_text_query
    query_terms = query.split(/\s+/).reject(&:blank?)
    customers = Customer.all
    customers = customers.full_text(query_terms) unless query_terms.empty?
    customers = customers.limit(10)

    respond_to do |format|
      format.json { render json: customers }
    end
  end

  # PUT /prints/cancel_job
  def cancel_job
    @print_job = PrintJob.find(params[:id])
    @cancelled = @print_job.cancel
  end

  def related_by_customer
    current_print = prints_scope.find(params[:id])
    print = current_print.related_by_customer(params[:type])

    redirect_to prints_scope.exists?(print.try(:id)) ? print : current_print
  end

  # /prints/1/change_comment
  def change_comment
    print = Print.find(params[:id])

    notice = if print.update_columns(comment_param)
               t('view.prints.comment_changed')
             else
               t('view.prints.comment_not_changed')
             end

    redirect_to print, notice: notice
  end

  private

  def comment_param
    params.require(:print).permit(:comment)
  end

  def load_customer
    id = current_customer.try(:id) || params[:customer_id]
    @customer = Customer.find(id) if id
  end

  def prints_scope
    scope = if @customer
              @customer.prints
            else
              current_user.admin ? Print.all : current_user.prints
            end

    scope = case params[:status]
            when 'pending'   then scope.pending
            when 'scheduled' then scope.scheduled
            when 'pay_later' then scope.pay_later
            else
              scope
            end

    scope
  end

  def print_params
    shared_attrs = [:id, :lock_version]

    params.require(:print).permit(
      :printer, :scheduled_at, :customer_id, :order_id, :auto_customer_name,
      :avoid_printing, :include_documents, :credit_password, :pay_later,
      :lock_version, :comment, print_jobs_attributes: [
        :document_id, :copies, :pages, :range, :print_id, :auto_document_name,
        :job_hold_until, :file_line_id, :print_job_type_id, *shared_attrs
      ], article_lines_attributes: [
        :print_id, :article_id, :units, :auto_article_name, *shared_attrs
      ], payments_attributes: [
        :amount, :paid, :paid_with, :payable_id, *shared_attrs
      ]
    )
  end

  def file_line_params
    file = params.require(:file_line).permit(file: [])[:file]
    file = file.first if file.is_a? Array
    { file: file }
  end
end
