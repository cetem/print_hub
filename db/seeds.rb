user = User.new(
  :name => 'Administrator',
  :last_name => 'Administrator',
  :username => 'admin',
  :email => 'admin@printhub.com',
  :language => 'es',
  :password => 'admin123',
  :password_confirmation => 'admin123',
  :admin => true,
  :enable => true
)

puts(user.save ? 'User [OK]' : user.errors.full_messages.join("\n"))