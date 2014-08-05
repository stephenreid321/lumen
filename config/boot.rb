# Defines our constants
RACK_ENV = ENV['RACK_ENV'] ||= 'development'  unless defined?(RACK_ENV)
PADRINO_ROOT = File.expand_path('../..', __FILE__) unless defined?(PADRINO_ROOT)

# Load our dependencies
require 'rubygems' unless defined?(Gem)
require 'bundler/setup'
Bundler.require(:default, RACK_ENV)

require 'net/imap'

Padrino.load!

I18n.enforce_available_locales = false

Mongoid.load!("#{PADRINO_ROOT}/config/mongoid.yml")
Mongoid.raise_not_found_error = false
