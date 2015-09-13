require 'rmega'

storage = Rmega.login('user', 'pass')

ARGV.each do |file|
  storage.root.upload(file)
end
