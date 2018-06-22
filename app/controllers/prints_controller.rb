class PrintsController < ApplicationController
  before_action :require_customer_or_user, except: [:revoke, :related_by_customer]
  before_action :require_admin_user, only: [:revoke, :related_by_customer]
  before_action :load_customer, except: [:can_be_associate_to_customer, :associate_to_customer]

  layout ->(controller) { controller.request.xhr? ? false : 'application' }

  # GET /prints
  # GET /prints.json
  def index
    @title = t('view.prints.index_title')
    order = if params[:status] == 'scheduled'
              { scheduled_at: :asc }
            else
              { created_at: :desc }
            end

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
      include_documents: session[:documents_for_printing],
      copy_from: params[:copy_from]
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
        if @print.errors && ([:credit_password, :printer] - @print.errors.keys).empty?
          report_validation_error(@print)
        end
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
      if @print.update(print_params)
        format.html { redirect_to(@print, notice: t('view.prints.correctly_updated')) }
        format.json  { head :ok }
      else
        if @print.errors && ([:credit_password, :printer] - @print.errors.keys).empty?
          report_validation_error(@print)
        end
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
    file_line = FileLine.create(file_line_params)

    respond_to do |format|
      if file_line&.persisted?
        @print = Print.new
        @print.print_jobs.build(file_line_id: file_line.id)
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
    docs = full_text_search_for(Document.enabled, params[:q])

    respond_to do |format|
      format.json { render json: docs }
    end
  end

  # GET /prints/autocomplete_for_article_name
  def autocomplete_for_article_name
    articles = full_text_search_for(Article.enabled, params[:q])

    respond_to do |format|
      format.json { render json: articles }
    end
  end

  # GET /prints/autocomplete_for_customer_name
  def autocomplete_for_customer_name
    customers = full_text_search_for(Customer.active, params[:q])

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

    notice = if print.update_columns(comment_param.to_h)
               t('view.prints.comment_changed')
             else
               t('view.prints.comment_not_changed')
             end

    redirect_to print, notice: notice
  end

  def can_be_associate_to_customer
    print = prints_scope.find(params[:id])

    if print.customer.present?
      render_json({ error: t('view.prints.customer_already_assigned') }); return
    end

    customer = Customer.find(params[:customer_id])
    unless customer.valid_password?(params[:password])
      render_json({ error: t('view.prints.invalid_password') }); return
    end

    free_credit = customer.free_credit
    total_price = print.price
    info = { from_credit: 0.0, to_pay: total_price }

    if free_credit >= total_price
      info[:from_credit] = total_price
      info[:to_pay] = 0.0
    elsif free_credit > 0
      info[:from_credit] = free_credit
      info[:to_pay] = total_price - free_credit
    end

    render_json({
      from_credit: t(
        'view.prints.using_customer_credit_in_assign',
        value: helpers.number_to_currency(info[:from_credit])
      ),
      to_pay: t(
        'view.prints.to_pay_in_assign',
        value: helpers.number_to_currency(info[:to_pay])
      ),
      to_pay_amount: info[:to_pay].round(2),
      from_credit_amount: info[:from_credit].round(2)
    })
  end

  def associate_to_customer
    print = prints_scope.find(params[:id])

    if print.customer.present?
      render_json({ error: t('view.prints.customer_already_assigned') }); return
    end

    customer = Customer.find(params[:customer_id])
    unless customer.valid_password?(params[:password])
      render_json({ error: t('view.prints.invalid_password') }); return
    end

    free_credit = customer.free_credit
    total_price = print.price

    amount = if free_credit >= total_price
               total_price
             elsif free_credit > 0
               free_credit
             end

    if amount && customer.use_credit(amount, params[:password])
      # customer_id is attr_readonly
      Print.transaction do
        Print.where(id: print.id).update_all(customer_id: customer.id)
        cash_amount = total_price - amount
        print.payments.update_all(paid: cash_amount, amount: cash_amount)
        print.payments.create!(paid: amount, amount: amount, paid_with: Payment::PAID_WITH[:credit])
      end

      render_json({ success: t('view.prints.customer_assigned') })
    else
      render_json({ error: t('view.prints.cant_assign_customer') })
    end
  rescue
    render_json({ error: t('view.prints.cant_assign_customer') })
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
      :lock_version, :customer_rfid, :comment, print_jobs_attributes: [
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

  def render_json(msg)
    respond_to do |format|
      format.json { render json: msg.to_json }
    end
  end

  def helpers
    @helper ||= Class.new do
      include ActionView::Helpers::NumberHelper
    end.new
  end
end
