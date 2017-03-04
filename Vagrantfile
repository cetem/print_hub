# File copied from https://github.com/Anomen/vagrant-selenium
# Thanks Anomen for the great work

VAGRANTFILE_API_VERSION = '2'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = 'ubuntu/trusty64'
  config.vm.box_url = 'https://vagrantcloud.com/ubuntu/boxes/trusty64/versions/14.04/providers/virtualbox.box'

  config.vm.network :forwarded_port, guest:4444, host:4444
  config.vm.network :private_network, ip: '192.168.33.10'
  config.vm.provision 'shell', path: 'vagrant_script.sh'

  config.vm.provider :virtualbox do |vb|
    vb.memory = 2024
    vb.cpus = 2
    vb.gui = true
  end
end
