class PrintQueuesController < ApplicationController
  def index
    @jobs = CustomCups.incompletes
    @users = User.where(username: @jobs.map(&:user)).map do |user|
      [user.username, user.to_s]
    end.to_h
  end

  def destroy
    msg = CustomCups.cancel(params[:id])
    msg = t('view.print_queues.job_cancelled') if msg.blank?

    redirect_to print_queues_url, notice: msg
  end
end
