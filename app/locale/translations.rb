Hash[
  Language.all.map { |language|

    h = {}    
    Hash[
      Translation.defaults.map { |k,v|          
        [k, language.translations.find_by(key: k).try(:value) || v]        
      }  
    ].each { |k,v|
      keys = k.split('.')
      prev_hash = h
      keys[0..-2].each { |key|
        prev_hash[key] = {} if !prev_hash[key]
        prev_hash = prev_hash[key]
      }
      prev_hash[keys.last] = v
    }
    
    [language.code, h]
  }
]