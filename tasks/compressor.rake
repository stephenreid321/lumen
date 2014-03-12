require 'yui/compressor'

namespace :compress do
  
  task :css  do
    path = 'app/assets/stylesheets'
    compressor = YUI::CssCompressor.new
    output = compressor.compress([
        'bootstrap.min.css',
        'bootstrap-theme.min.css',
        'font-awesome.min.css',
        'bootstrap-wysihtml5-0.0.3.css',
        'chosen.min.css',
        'chosen-bootstrap.css',
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
        'wysihtml5-0.3.0.js',
        'bootstrap-wysihtml5-0.0.3.js',
        'jquery.confirm.js',
        'jquery.deparam.js',
        'jquery.typing-0.3.0.min.js',
        'chosen.jquery.min.js',
        'bootstrap-datepicker.js',
        'app.js'
      ].map { |x| File.read("#{path}/#{x}") }.join("\n"))    
    File.open("#{path}/compressed.js", 'w') { |file| file.write(output) }
  end  
  
end

task :compress => ['compress:css', 'compress:js']