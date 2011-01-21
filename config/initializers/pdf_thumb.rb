# TODO: mover a lib/paperclip_processors cuando solucionen el error con Rails 3
module Paperclip
  class PdfThumb < Processor

    def initialize(file, options = {}, attachment = nil)
      super(file, options, attachment)

      @format = options[:format] || :png
      @resolution = options[:resolution] || 72
    end

    def make
      thumb = RGhost::Convert.new(@file.path)
      page = thumb.to @format, :resolution => @resolution

      raise 'Error generating PDF thumbs' if thumb.error

      page
    end
  end
end