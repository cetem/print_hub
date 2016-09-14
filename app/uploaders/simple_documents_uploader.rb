class SimpleDocumentsUploader < CarrierWave::Uploader::Base

  storage :file

  def store_dir
    model_id = ('%09d' % model.id).scan(/\d{3}/).join('/')

    "private/files/#{model_id}"
  end

  def extension_white_list
    %w(pdf)
  end
end
