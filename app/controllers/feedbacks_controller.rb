class FeedbacksController < ApplicationController
  layout false
  #->(controller) { controller.request.xhr? ? false : 'application' }

  # POST /feedbacks/item/score
  def create
    @feedback = Feedback.new(create_feedback_params)

    respond_to do |format|
      if @feedback.save
        format.html { render @feedback.positive ? 'positive' : 'negative' }
      end
    end
  end

  # PUT /feedbacks/1
  def update
    @feedback = Feedback.negative.find(params[:id])

    respond_to do |format|
      if @feedback.update(update_feedback_params)
        format.html { render 'negative_comment' }
      end
    end
  end

  private

  # Attributos permitidos
  def create_feedback_params
    params[:positive] = params[:score] == 'positive'
    params[:customer_id] = current_customer.try(:id)

    params.permit(:item, :positive, :customer_id)
  end

  def update_feedback_params
    params.require(:feedback).permit(:comments)
  end
end
