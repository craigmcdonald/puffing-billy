require 'billy'

module Billy
  module Browsers
    class Capybara

      DRIVERS = {
        poltergeist: 'capybara/poltergeist',
        webkit: 'capybara/webkit',
        selenium: 'selenium/webdriver'
      }

      def self.register_drivers
        DRIVERS.each do |name, driver|
          begin
            require driver
            send("register_#{name}_driver")
          rescue LoadError
          end
        end
      end

      private

      def self.register_poltergeist_driver
        ::Capybara.register_driver :poltergeist_billy do |app|
          options = {
            phantomjs_options: [
              '--ignore-ssl-errors=yes',
              "--proxy=#{Billy.proxy.host}:#{Billy.proxy.port}"
            ]
          }
          # Stop PhantomJS outputting console messages when rspec runs
          # This requires a class called Rails which responds to .logger
          # and also a class called Rails::Railtie which responds to
          # .railtie_name & .rake_tasks
          options.merge!({phantomjs_logger: Rails.logger}) if defined?(Rails)
          ::Capybara::Poltergeist::Driver.new(app, options)
        end
      end

      def self.register_webkit_driver
        ::Capybara.register_driver :webkit_billy do |app|
          options = {
            ignore_ssl_errors: true,
            proxy: {host: Billy.proxy.host, port: Billy.proxy.port}
          }
          ::Capybara::Webkit::Driver.new(app, ::Capybara::Webkit::Configuration.to_hash.merge(options))
        end
      end

      def self.register_selenium_driver
        ::Capybara.register_driver :selenium_billy do |app|
          profile = Selenium::WebDriver::Firefox::Profile.new
          profile.assume_untrusted_certificate_issuer = false
          profile.proxy = Selenium::WebDriver::Proxy.new(
            http: "#{Billy.proxy.host}:#{Billy.proxy.port}",
            ssl: "#{Billy.proxy.host}:#{Billy.proxy.port}")
          ::Capybara::Selenium::Driver.new(app, profile: profile)
        end

        ::Capybara.register_driver :selenium_chrome_billy do |app|
          ::Capybara::Selenium::Driver.new(
            app, browser: :chrome,
            switches: ["--proxy-server=#{Billy.proxy.host}:#{Billy.proxy.port}"]
          )
        end
      end

    end
  end
end
