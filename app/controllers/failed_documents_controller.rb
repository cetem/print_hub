class FailedDocumentsController < ApplicationController
  before_action :set_failed_document, only: [:show, :edit, :update]

  def index
    @searchable = true

    @failed_documents = if params[:unavailable]
                          FailedDocument.unavailable
                        else
                          FailedDocument.available
                        end

    if params[:q].present?
      query        = params[:q].sanitized_for_text_query
      @query_terms = query.split(/\s+/).reject(&:blank?)
      @failed_documents   = @failed_documents.full_text(@query_terms) unless @query_terms.empty?
    end


    @failed_documents = @failed_documents.page params[:page]
  end

  def show
  end

  def new
    @failed_document = FailedDocument.new
  end

  def edit
  end

  def create
    @failed_document = FailedDocument.new(failed_document_params)

    if @failed_document.save
      redirect_to @failed_document, notice: t('view.failed_documents.correctly_created')
    else
      render :new
    end
  end

  def update
    if @failed_document.update(failed_document_params)
      redirect_to @failed_document, notice: t('view.failed_documents.correctly_updated')
    else
      render :edit
    end
  end

  private
    def set_failed_document
      @failed_document = FailedDocument.find(params[:id])
    end

    def failed_document_params
      params.require(:failed_document).permit(:name, :unit_price, :stock, :comment)
    end
end
