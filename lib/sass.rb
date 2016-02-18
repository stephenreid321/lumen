require 'sass'
require 'sass/util'
require 'sass/script'

DEFAULT_COLORS = {
  'primary' => '#F5D74B',
  'primary-contrast' => '#222222',
  'primary-dark' => '#CDA70D',
  'secondary' => '#E74C3C',
  'secondary-dark' => '#CD4435',
  'secondary-light' => '#F9DFDD',
  'grey-light' => '#ECF0F1',
  'grey-mid' => '#D6DBDF',
  'dark-contrast' => '#F5D74B'
}

module Sass::Script::Functions
  def colors(color)
    color = color.to_s.gsub('"','')       
    v = ENV["#{color.underscore.upcase}_COLOR"] || DEFAULT_COLORS[color]
    Sass::Script::Value::String.new(v)
  end 
end