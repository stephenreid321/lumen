require 'yui/compressor'
require_relative '../lib/assets'

namespace :compress do
  
  task :css  do
    path = 'app/assets/stylesheets'
    compressor = YUI::CssCompressor.new
    output = compressor.compress(STYLESHEETS.map { |x| File.read("#{path}/#{x}") }.join("\n"))    
    File.open("#{path}/compressed.css", 'w') { |file| file.write(output) }
  end
  
  task :js do
    path = 'app/assets/javascripts'
    compressor = YUI::JavaScriptCompressor.new
    output = compressor.compress(JAVASCRIPTS.map { |x| File.read("#{path}/#{x}") }.join("\n"))    
    File.open("#{path}/compressed.js", 'w') { |file| file.write(output) }
  end  
  
end

task :compress => ['compress:css', 'compress:js']