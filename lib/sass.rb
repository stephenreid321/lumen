require 'sass'
require 'sass/util'
require 'sass/script'

DEFAULT_COLORS = {
  'primary' => '#228DFF',
  'primary-contrast' => '#ffffff',
  'secondary' => '#228DFF',
  'grey-light' => '#ECF0F1',
  'grey-mid' => '#D6DBDF',
  'dark' => '#333333',
  'dark-contrast' => '#228DFF'
}

module Sass::Script::Functions
  def colors(color)
    color = color.to_s.gsub('"','')       
    v = Config["#{color.underscore.upcase}_COLOR"] || DEFAULT_COLORS[color]
    Sass::Script::Value::Color.from_hex(v)
  end 
end