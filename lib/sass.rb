require 'sass'
require 'sass/util'
require 'sass/script'

module Sass::Script::Functions
  def colors(color)
    color = color.to_s.gsub('"','')
    
    defaults = {
      'primary' => '#F5D74B',
      'primary-contrast' => '#222222',
      'primary-dark' => '#CDA70D',
      'secondary' => '#E74C3C',
      'secondary-dark' => '#CD4435',
      'secondary-light' => '#F9DFDD',
      'grey-light' => '#ECF0F1',
      'grey-mid' => '#D6DBDF'
    }
    
    v = ENV["#{color.underscore.upcase}_COLOR"] || defaults[color]
    Sass::Script::Value::String.new(v)
  end 
end