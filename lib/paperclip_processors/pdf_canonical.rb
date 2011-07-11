module Paperclip
  class PdfCanonical < Processor

    def initialize(file, options = {}, attachment = nil)
      super(file, options, attachment)

      @format = options[:format] || :pdf
      @resolution = options[:resolution] || 1200
      @paper_size = options[:paper_size] || :a4
    end

    def make
      filename = "gs_thumb_#{Time.now.to_i}_#{rand(100000)}.pdf"
      file_path = File.join(Rails.root, 'tmp', filename)
      options = [
        '-dQUIET',
        '-dBATCH',
        '-dSAFER',
        '-dNOPAUSE',
        '-dNOPROMPT',
        '-dDOINTERPOLATE',
        '-sDEVICE=pdfwrite',
        "-sPAPERSIZE=#{@paper_size}",
        "-r#{@resolution}x#{@resolution}",
        "-sOutputFile=\"#{file_path}\""
      ]
      gs_command = "gs #{options.join(' ')} -- \"#{@file.path}\""
      out = %x{#{gs_command} 2>&1}

      File.new(file_path, 'r') if out.blank?
    end
  end
end