class Users::SessionsController < Devise::SessionsController
  before_action :require_no_user, only: [:new, :create]
  before_action :require_user, only: :destroy

  before_action :set_title

  private

  def set_title
    @title = t("view.user_sessions.#{action_name}_title")
  end
end
