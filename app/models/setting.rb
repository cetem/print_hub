class Setting < RailsSettings::Settings
  attr_readonly :var
  attr_accessible :var, :value, :lock_version

  # Restricciones
  validates :var, :value, presence: true

  def to_param
    self.var
  end

  def name
    I18n.t("view.settings.names.#{self.var}")
  end
end