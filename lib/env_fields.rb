class EnvFields
  
  def self.fields(model)    
    varname = "ENV_FIELDS_#{model.to_s.upcase}"
    ENV[varname] ? Hash[*ENV[varname].split(',').map { |pair| pair.split(':').map { |x| x.to_sym } }.flatten(1)] : {}    
  end
  
  def self.set(model)   
    fields(model).each { |fieldname, fieldtype|
      case fieldtype
      when :text
        model.field fieldname, :type => String
      when :text_area
        model.field fieldname, :type => String
      when :wysiwyg
        model.field fieldname, :type => String
      when :file
        model.field "#{fieldname}_uid".to_sym, :type => String
        model.field "#{fieldname}_name".to_sym, :type => String
        model.send(:dragonfly_accessor, fieldname)
      end
    }
  end
  
  def self.display(fieldtype, result)
    case fieldtype
    when :text
      result
    when :text_area
      result.gsub("\n",'<br />')
    when :wysiwyg
      result
    when :file
      %Q{<i class="fa fa-download"></i> <a target="_blank" href="#{result.remote_url}">#{result.name}</a>}
    end
  end
  
  
end
  