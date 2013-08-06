# Cantidad de líneas por página
APP_LINES_PER_PAGE = 16
# Umbral crédito / precio para determinar si se imprime o no un pedido
CREDIT_THRESHOLD = 0.7
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
# Directorio temporal para imágenes de códigos de barra
TMP_BARCODE_IMAGES = File.join(Rails.root, 'tmp', 'codes')
# Validez de los tokens para cambiar contraseña y activar cuenta
TOKEN_VALIDITY = 1.day
# Cantidad de horas maximas para un turno
SHIFT_MAX_RANGE = 16.hours
# Path privado private/
PRIVATE_PATH = Pathname.new("#{Rails.root}/private")
# RegEx for private printers
PRIVATE_PRINTERS_REGEXP = Regexp.new(APP_CONFIG['private_printers'])
