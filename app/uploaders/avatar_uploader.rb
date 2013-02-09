# encoding: utf-8

class AvatarUploader < CarrierWave::Uploader::Base
  include CarrierWave::RMagick

  storage :file
  after :remove, :delete_empty_upstream_dirs
  process convert: 'png'

  def store_dir
    model_id = ('%09d' % model.id).scan(/\d{3}/).join('/')
  
    "private/avatars/#{model_id}"
  end

  version :medium do
    process resize_to_fit: [200, 200]
    process convert: 'png'
  end

  version :mini, from_version: :medium do
    process resize_to_fit: [35, 35]
    process convert: 'png'
  end

  def extension_white_list
    %w(jpg jpeg gif png)
  end

  def filename
    if original_filename.present? && super.present?
      "#{super.chomp(File.extname(super))}.png"
    end
  end

  private

  def delete_empty_upstream_dirs
    Dir.delete ::File.expand_path(store_dir, root)
    Dir.delete ::File.expand_path(base_store_dir, root)
  rescue SystemCallError
    true
  end
end
