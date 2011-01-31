ValidatesTimeliness.setup do |config|
  # Add validation helpers to these classes
  config.extend_orms = [ :active_record ]
  config.use_plugin_parser = true
  #
  # Set the dummy date part for a time type values.
  # config.dummy_date_for_time_type = [ 2000, 1, 1 ]
  #
  # Ignore errors when restriction options are evaluated
  config.ignore_restriction_errors = true
  #
  # Re-display invalid values in date/time selects
  config.enable_date_time_select_extension!
  #
  # Handle multiparameter date/time values strictly
  #config.enable_multiparameter_extension!
  #
  # Shorthand date and time symbols for restrictions
  # config.restriction_shorthand_symbols.update()
end

Timeliness.use_euro_formats