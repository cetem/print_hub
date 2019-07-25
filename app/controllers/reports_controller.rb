class ReportsController < ApplicationController
  before_action :require_user

  def printed_documents
    if params[:interval]
      @from_date, @to_date = make_datetime_range(interval_params)
      @stub_print_jobs = PrintJob.documents_copies_between([@from_date, @to_date])
    end
  end

  private

  def interval_params
    params.require(:interval).permit(:from, :to)
  end
end
