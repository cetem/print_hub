# Cantidad de líneas por página
APP_LINES_PER_PAGE = 16
# Umbral crédito / precio para determinar si se imprime o no un pedido
CREDIT_THRESHOLD = APP_CONFIG['credit_threshold']
# Adaptador de base de datos
DB_ADAPTER = ActiveRecord::Base.connection.adapter_name
# Idiomas disponibles
LANGUAGES = [:es]
# Dominio público
PUBLIC_DOMAIN = APP_CONFIG['public_host'].split(':').first
# Puerto público
PUBLIC_PORT = APP_CONFIG['public_host'].split(':')[1]
# Protocolo público
PUBLIC_PROTOCOL = 'https'
# Host público
PUBLIC_HOST = PUBLIC_PROTOCOL + '://' + PUBLIC_DOMAIN
# Directorio temporal para imágenes de códigos de barra
TMP_BARCODE_IMAGES = Rails.root.join('tmp', 'codes')
# Validez de los tokens para cambiar contraseña y activar cuenta
TOKEN_VALIDITY = 1.day
# Cantidad de horas maximas para un turno
SHIFT_MAX_RANGE = 16.hours
# Path privado private/
PRIVATE_PATH = Rails.root.join('private')
# RegEx for private printers
PRIVATE_PRINTERS_REGEXP = Regexp.new(APP_CONFIG['private_printers'])
# Tmp files
TMP_FILES = Rails.root.join('tmp')
