# frozen_string_literal: true

require 'yaml'

# This class is fork form TangRufus/trellis@b4a2d87
# See: https://github.com/TangRufus/trellis/commit/b4a2d87d911d85ef863ce6fe25c
#
# TODO: Remove after roots/trellis#890 is merged.
#
module VagrantPlugins
  module TrellisCert
    class Config
      def initialize(root_path:)
        @root_path = root_path
      end

      def multisite_subdomains?
        @using_multisite_subdomains ||= begin
          wordpress_sites.any? do |(_name, site)|
            site.dig('multisite', 'enabled') && site.dig('multisite', 'subdomains')
          end
        end
      end

      def canonicals
        @canonicals ||= site_hosts.map { |host| host['canonical'] }
      end

      def redirects
        @redirects ||= site_hosts.flat_map { |host| host['redirects'] }.compact
      end

      def site_hosts
        @site_hosts ||= begin
          wordpress_sites.flat_map { |(_name, site)| site['site_hosts'] }.tap do |hosts|
            fail_with message: template_content if malformed?(site_hosts: hosts)
          end
        end
      end

      def wordpress_sites
        @wordpress_sites ||= begin
          content['wordpress_sites'].tap do |sites|
            fail_with message: "No sites found in #{path}." if sites.to_h.empty?
          end
        end
      end

      def content
        @content ||= begin
          fail_with message: "#{path} was not found. Please check `root_path`." unless exist?
          YAML.load_file(path)
        end
      end

      private

      def malformed?(site_hosts:)
        site_hosts.any? do |host|
          !host.is_a?(Hash) || !host.key?('canonical')
        end
      end

      def exist?
        File.exist?(path)
      end

      def path
        File.join(@root_path, 'group_vars', 'development', 'wordpress_sites.yml')
      end

      def template_content
        File.read(File.join(@root_path, 'roles', 'common', 'templates', 'site_hosts.j2')).sub!('{{ env }}', 'development').gsub!(/com$/, 'dev')
      end

      def fail_with(message:)
        raise Vagrant::Errors::VagrantError.new, message
      end
    end
  end
end
