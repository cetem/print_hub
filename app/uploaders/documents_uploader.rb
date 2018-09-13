class DocumentsUploader < CarrierWave::Uploader::Base
  include ::CarrierWave::Backgrounder::Delay
  include CarrierWave::PdfThumb

  storage :file
  after :remove, :delete_empty_upstream_dirs

  def store_dir
    model_id = ('%09d' % model.id).scan(/\d{3}/).join('/')

    "private/files/#{model_id}"
  end

  # Create 1, 2 or 3 first pages thumbs from PDF
  # pdf_thumb and pdf_mini_thumb versions
  # pdf_thumb pdf_thumb_2 pdf_thumb_3
  %w(pdf_thumb pdf_mini_thumb).each do |thumb|
    resolution = thumb.match(/mini/) ? 24 : 48

    version thumb.to_sym, if: :have_at_least_1_page? do
      process make_thumb: [:png, resolution, 1]

      def full_filename(for_file)
        file_url = File.basename(for_file, File.extname(for_file))
        "#{file_url}_#{version_name}.png"
      end
      @versions_ready = true
    end

    [2, 3].each do |i|
      version :"#{thumb}_#{i}", if: :"have_at_least_#{i}_pages?" do
        process make_thumb: [:png, resolution, i]

        def full_filename(for_file)
          file_url = File.basename(for_file, File.extname(for_file))
          "#{file_url}_#{version_name}.png"
        end
      end # numeric-version
    end # 2-3 each
  end # thumb each

  def extension_white_list
    %w(pdf)
  end

  def method_missing(method_name, *args)
    if method_name =~ /^have_at_least_(\d)_page/
      model.pages.to_i >= Regexp.last_match(1).to_i
    else
      super
    end
  end

  private

    def delete_empty_upstream_dirs
      Dir.delete ::File.expand_path(store_dir, root)
    rescue
      true
    end
end
