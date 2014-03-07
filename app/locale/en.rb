{
  en: Hash[
    {
      organisation: 'organisation',
      organisations: 'organisations',
      host_organisation: 'host organisation',
      sector: 'sector',
      sectors: 'sectors',
      position: 'position',
      positions: 'positions',      
      account_tagship: 'area of expertise',
      account_tagships: 'areas of expertise'  
    }.map { |k,v| [k, Translation.find_by(key: k).try(:value) || v] } 
  ]
}
