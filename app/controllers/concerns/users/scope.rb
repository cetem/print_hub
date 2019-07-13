module Users::Scope
  extend ActiveSupport::Concern

  def user_scope
    user_id = params[:user_id] || params[:id]
    if current_user.admin? && user_id.present?
      if user_id.is_a?(String) && user_id.match?(::UUID_REGEX)
        User.find_by(abaco_id: user_id)
      else
        User.find(user_id)
      end
    else
      current_user
    end
  end
end
