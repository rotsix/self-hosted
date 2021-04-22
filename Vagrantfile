# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "generic/arch"
  config.vm.provider :libvirt do |lv|
    lv.cpus = "2"
    lv.memory = "2048"
  end

  config.vm.synced_folder ".", "/vagrant"
  config.vm.synced_folder "~/src/website", "/vagrant/web/html"
  config.vm.synced_folder "/etc/pacman.d/hooks", "/etc/pacman.d/hooks"

  config.vm.define :host do |host|
    host.vm.network :forwarded_port, guest: 80, host: 80
    host.vm.network :forwarded_port, guest: 81, host: 81
    host.vm.network :forwarded_port, guest: 443, host: 443
    #host.vm.network :private_network, type: "dhcp"
    host.vm.hostname = "host"
  end

  config.vm.provision :ansible do |ansible|
    ansible.playbook = "playbook.yml"
  end
end
