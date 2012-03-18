require 'barby/barcode/qr_code'
require 'barby/outputter/svg_outputter'
require 'barby/outputter/png_outputter'

# Create (if no exist) a temporal directory for codes
FileUtils.mkdir_p TMP_BARCODE_IMAGES