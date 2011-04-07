# TODO: mover a lib/paperclip_processors cuando solucionen el error con Rails 3
module Paperclip
  class PdfThumb < Processor

    def initialize(file, options = {}, attachment = nil)
      super(file, options, attachment)

      @format = options[:format] || :png
      @resolution = options[:resolution] || 72
      @page = options[:page] || 1
    end

    def make
      thumb = RGhost::Convert.new(@file.path)
      pages = thumb.to @format, :resolution => @resolution, :multipage => true,
        :range => @page..@page

      raise "Error generating PDF thumbs: #{thumb.error}" if thumb.error

      File.new(pages.first, 'r') if pages.first
    end
  end
end