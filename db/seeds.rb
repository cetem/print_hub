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
  Setting.price_per_one_sided_copy = '0.10'
  Setting.price_per_two_sided_copy = '0.07'
rescue => ex
  p ex
else
  puts 'Setting [OK]'
end