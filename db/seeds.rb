user = User.create(
  :name => 'Administrator',
  :last_name => 'Administrator',
  :username => 'admin',
  :email => 'admin@printhub.com',
  :language => 'es',
  :password => 'admin123',
  :password_confirmation => 'admin123',
  :enable => true
)

if user.valid?
  puts 'User [OK]'
else
  puts user.errors.full_messages.join("\n")
end