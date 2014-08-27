VAGRANTFILE_API_VERSION = "2"

path = "#{File.dirname(__FILE__)}"

require 'yaml'
require path + '/scripts/lindeluk.rb'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  Lindeluk.configure(config, YAML::load(File.read(path + '/Lindeluk.yaml')))
end
