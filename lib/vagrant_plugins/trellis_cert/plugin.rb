# frozen_string_literal: true

module VagrantPlugins
  module TrellisCert
    class Plugin < Vagrant.plugin('2')
      name Identity.name

      description Identity.description

      command 'trellis-cert' do
        require_relative 'command/root'
        Command::Root
      end
    end
  end
end
