# Usuario por defecto
user = User.create!(
  name: 'Administrator',
  last_name: 'Administrator',
  username: 'admin',
  email: 'admin@printhub.com',
  language: 'es',
  password: 'admin123',
  password_confirmation: 'admin123',
  admin: true,
  enable: true
)

# Configuración por defecto
begin
  PrintJobType.create!(
    name: 'Common',
    price: '0.10',
    two_sided: true,
    default: true
  )
rescue => ex
  p ex
else
  puts 'Setting [OK]'
end
