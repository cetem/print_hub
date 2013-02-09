module CarrierWave
  module PdfThumb
    extend ActiveSupport::Concern

    module ClassMethods
      def make_thumb(format, resolution, page)
        process make_thumb: [format, resolution, page]
      end
    end

    def make_thumb(format = :png, resolution = 72, page = 1)
      cache_stored_file! unless cached?

      dir = File.dirname(current_path)
      tmp_path = File.join(dir, 'tmpfile')

      File.rename current_path, tmp_path

      thumb = RGhost::Convert.new(tmp_path)
      pages = thumb.to format, resolution: resolution, multipage: true,
        range: [page]
      
      FileUtils.mv pages.first, current_path if pages.present?
  
       # delete tmp file
       File.delete tmp_path
    end
  end
end
