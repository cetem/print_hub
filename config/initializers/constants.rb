# Cantidad de líneas por página
APP_LINES_PER_PAGE = 32
# Subdominio donde ingresan los clientes
CUSTOMER_SUBDOMAIN = 'fotocopia'
# Adaptador de base de datos
DB_ADAPTER = ActiveRecord::Base.connection.adapter_name
# Expresión regular para validar direcciones de correo
EMAIL_REGEXP = /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
# Idiomas disponibles
LANGUAGES = [:es]
# Dirección de email para las notificaciones
NOTIFICATIONS_EMAIL = 'fotocopia@frm.utn.edu.ar'
