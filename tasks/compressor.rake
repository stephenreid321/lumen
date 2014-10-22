require 'yui/compressor'

namespace :compress do
  
  task :css  do
    path = 'app/assets/stylesheets'
    compressor = YUI::CssCompressor.new
    output = compressor.compress([
        'lumen.bootswatch.css',
        'font-awesome.min.css',
        'summernote.css',
        'bootstrap-stacked-tabs.css',      
        'datepicker3.css',
        'app.css',      
        'news.css'
      ].map { |x| File.read("#{path}/#{x}") }.join("\n"))    
    File.open("#{path}/compressed.css", 'w') { |file| file.write(output) }
  end
  
  task :js do
    path = 'app/assets/javascripts'
    compressor = YUI::JavaScriptCompressor.new
    output = compressor.compress([
        'jquery-1.9.1.min.js',
        'bootstrap.min.js',
        'bootstrap3-typeahead.min.js',
        'summernote.min.js',
        'jquery.deparam.js',
        'jquery.typing-0.3.0.min.js',
        'bootstrap-datepicker.js',
        'jquery.geopicker.js',
        'app.js'
      ].map { |x| File.read("#{path}/#{x}") }.join("\n"))    
    File.open("#{path}/compressed.js", 'w') { |file| file.write(output) }
  end  
  
end

task :compress => ['compress:css', 'compress:js']