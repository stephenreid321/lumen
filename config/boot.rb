# Defines our constants
RACK_ENV = ENV['RACK_ENV'] ||= 'development' unless defined?(RACK_ENV)
PADRINO_ROOT = File.expand_path('../..', __FILE__) unless defined?(PADRINO_ROOT)

# Load our dependencies
require 'rubygems' unless defined?(Gem)
require 'bundler/setup'
Bundler.require(:default, RACK_ENV)

require 'net/imap'

Mongoid.load!("#{PADRINO_ROOT}/config/mongoid.yml")
Mongoid.raise_not_found_error = false
Mongoid.logger.level = Logger::INFO
Mongo::Logger.logger.level = Logger::INFO

Padrino.load!

Delayed::Worker.max_attempts = 1
Delayed::Worker.destroy_failed_jobs = false

I18n.enforce_available_locales = false