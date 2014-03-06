{
  en: Hash[
    {
      organisation: 'organisation',
      organisations: 'organisations',
      sector: 'sector',
      sectors: 'sectors',
      account_tagship: 'area of expertise',
      account_tagships: 'areas of expertise'  
    }.map { |k,v| [k, Translation.find_by(key: k).try(:value) || v] } 
  ]
}
