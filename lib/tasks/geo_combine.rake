

# https://issues.cul.columbia.edu/projects/GEO/issues/GEO-14
# Actually, I can't simply transform the Tufts and Harvard FGDC XML 
# to GeoBlacklight. Some important values in dct_references are not 
# in the FGDC files. For example, I don't have their GeoServer URL.


# #
# # Add a geocombine:transform rake task to transform any
# #  downloaded FGDC XML files to GeoBlacklight JSON format
# #
# 
# require 'find'
# 
# namespace :geocombine do
#   ogm_path = ENV['OGM_PATH'] || 'tmp/opengeometadata'
#   solr_url = ENV['SOLR_URL'] || 'http://127.0.0.1:8983/solr/blacklight-core'
# 
#   desc 'Index all of the FGDC XML documents'
#   task :index_fgdc do
#     solr = RSolr.connect :url => solr_url
#     Find.find(ogm_path) do |path|
#       next unless path =~ /.*fgdc.xml$/
#       # doc = JSON.parse(File.read(path))
#       fgdc_xml = File.read(path)
#       geobl_json = fgdc2geobl(path, fgdc_xml)
#       doc = JSON.parse(geobl_json)
#       begin
#         solr.update params: { commitWithin: 500, overwrite: true },
#                     data: [doc].to_json,
#                     headers: { 'Content-Type' => 'application/json' }
# 
#       rescue RSolr::Error::Http => error
#         puts error
#       end
#     end
#   end
# 
# end