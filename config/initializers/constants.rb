# Cantidad de líneas por página
APP_LINES_PER_PAGE = 16
# Subdominio donde ingresan los clientes
CUSTOMER_SUBDOMAIN = 'fotocopia'
# Umbral crédito / precio para determinar si se imprime o no un pedido
CREDIT_THRESHOLD = 0.7
# Dominio público
PUBLIC_DOMAIN = APP_CONFIG['public_host'].split(':').first
# Puerto público
PUBLIC_PORT = APP_CONFIG['public_host'].split(':')[1]
# Protocolo público
PUBLIC_PROTOCOL = 'http'
# Adaptador de base de datos
DB_ADAPTER = ActiveRecord::Base.connection.adapter_name
# Idiomas disponibles
LANGUAGES = [:es]
# Validez de los tokens para cambiar contraseña y activar cuenta
TOKEN_VALIDITY = 1.day