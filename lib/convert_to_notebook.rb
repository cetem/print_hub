module ConvertToNotebook
  def self.convert(file_path)
    timeout = 60 * 20

    filename = Shellwords.escape(
      File.basename(file_path)
    )
    abs_path = Shellwords.escape(
      Rails.root.join(TMP_FILES, file_path)
    )

    title = ['notebooks', Time.now.to_i.to_s].join('-')

    `pdftops -level3 #{abs_path} - | ps2ps - - | psbook | ps2pdf - - | lp -o media=a5 -o number-up=2 -o fit-to-page -t "#{title}" -o ppi=1200 -d Virtual_PDF_Printer`

    printed_file = Dir.home + '/PDF/' + title + '.pdf'
    loop do
      break if File.exist?(printed_file)
      return if (timeout -= 2).zero?
      sleep 2
    end
    `mv #{printed_file} #{PRIVATE_PATH.to_s + '/notebooks/' + filename}`

    `rm #{Shellwords.escape(Rails.root.join('tmp', 'notebooks', filename).to_s)}`
  end
end
