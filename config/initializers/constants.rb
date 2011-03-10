# Cantidad de líneas por página
APP_LINES_PER_PAGE = 16
# Expresión regular para validar direcciones de correo
EMAIL_REGEXP = /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
# Idiomas disponibles
LANGUAGES = [:es]
# Adaptador de base de datos
DB_ADAPTER = ActiveRecord::Base.connection.adapter_name
