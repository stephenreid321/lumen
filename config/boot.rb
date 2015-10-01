# Defines our constants
RACK_ENV = ENV['RACK_ENV'] ||= 'development'  unless defined?(RACK_ENV)
PADRINO_ROOT = File.expand_path('../..', __FILE__) unless defined?(PADRINO_ROOT)

# Load our dependencies
require 'rubygems' unless defined?(Gem)
require 'bundler/setup'
Bundler.require(:default, RACK_ENV)

Rack::Timeout.timeout = 25

require 'net/imap'
require 'net/scp'

Padrino.load!

Delayed::Worker.max_attempts = 1
Delayed::Worker.destroy_failed_jobs = false

I18n.enforce_available_locales = false

Mongoid.load!("#{PADRINO_ROOT}/config/database.yml")
Mongoid.raise_not_found_error = false
