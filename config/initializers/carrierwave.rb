require 'carrierwave_processors/full_filename_postfixed'
require 'carrierwave_processors/pdf_thumb'

CarrierWave.configure do |config|
  config.root = Rails.root
end
