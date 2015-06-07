class CustomersFilesUploader < CarrierWave::Uploader::Base
  storage :file
  after :remove, :delete_empty_upstream_dirs

  def store_dir
    model_id = ('%08d' % model.id)
    "private/customers_files/#{model_id}"
  end

  def extension_white_list
    %w(pdf)
  end

  def delete_empty_upstream_dirs
    Dir.delete ::File.expand_path(store_dir, root)
    Dir.delete ::File.expand_path(base_store_dir, root)
  rescue SystemCallError
    true
  end
end
