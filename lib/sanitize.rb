if Config['SANITIZE']
  
  Dir.entries("#{PADRINO_ROOT}/models").select { |filename| filename.ends_with?('.rb') }.map { |filename| filename.split('.rb').first.camelize.constantize }.each { |model|
    model.fields.map { |k,v| k if v.type == String }.compact.each { |f|
      model.before_validation do
        self.send("#{f}=", Sanitize.fragment(self.send(f), Sanitize::Config::RELAXED)) if self.send(f)
      end
    }
  }
  
end