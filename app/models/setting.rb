class Setting < RailsSettings::Settings
  attr_accessible :var, :value, :lock_version
  attr_readonly :var

  # Restricciones
  validates :var, :value, presence: true

  def to_param
    self.var
  end

  def name
    I18n.t("view.settings.names.#{self.var}")
  end
end