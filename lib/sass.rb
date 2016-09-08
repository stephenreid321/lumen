require 'sass'
require 'sass/util'
require 'sass/script'

DEFAULT_COLORS = {
  'primary' => '#F5D74B',
  'primary-contrast' => '#222222',
  'secondary' => '#E74C3C',
  'grey-light' => '#ECF0F1',
  'grey-mid' => '#D6DBDF',
  'dark' => '#333333',
  'dark-contrast' => '#F5D74B'
}

module Sass::Script::Functions
  def colors(color)
    color = color.to_s.gsub('"','')       
    v = Config["#{color.underscore.upcase}_COLOR"] || DEFAULT_COLORS[color]
    Sass::Script::Value::Color.from_hex(v)
  end 
end