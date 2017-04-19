require 'open-uri'
require 'net/ssh'

require 'fgdc2geobl'
include Fgdc2Geobl

require 'fgdc2html'
include Fgdc2Html

# Keep one older iteration - very useful for debugging
fgdc_current = File.join(Rails.root, "public/metadata/fgdc/current/")
fgdc_old = File.join(Rails.root, "public/metadata/fgdc/old/")
fgdc_html_dir = File.join(Rails.root, "public/metadata/fgdc/html/")
geobl_current = File.join(Rails.root, "public/metadata/geobl/current/")
geobl_old = File.join(Rails.root, "public/metadata/geobl/old/")
json_filename = 'geoblacklight.json'

namespace :metadata do
  desc "Download the FGDC XML"
  task :download => :environment do
    FGDC_METADATA_URL = APP_CONFIG['fgdc_metadata_url']

    FileUtils.rm_rf(fgdc_old)
    FileUtils.mv(fgdc_current, fgdc_old) if File.exists?(fgdc_current)
    FileUtils.mkdir_p(fgdc_current)

    begin
      puts "Downloading #{FGDC_METADATA_URL}..."
      download = open(FGDC_METADATA_URL)
      IO.copy_stream(download, "#{fgdc_current}/metadata.zip")
      puts "Download successful."
    rescue => ex
      puts "Download unsuccessful:  #{ex}"
      next
    end


    puts "Unzipping metadata.zip..."
    if system("unzip -q -n #{fgdc_current}/*zip -d #{fgdc_current}")
      puts("Unzip successful")
    else
      puts("Unzip unsuccessful")
      next
    end
  end

  desc "Validate that download links point to actual files"
  task :validate_downloads, [:file_pattern] => :environment do |t, args|
    file_pattern = args[:file_pattern] || "."

    host = 'cunix.columbia.edu'
    http_dir  = '/www/data/acis/eds/gis/images'
    https_dir  = '/wwws/data/acis/eds/dgate/studies/C1301/data'

    ssh_cmd = "ssh -l litoserv #{host} /bin/ls #{http_dir}"
    output = `#{ssh_cmd}`
    http_files = output.split("\n").sort

    ssh_cmd = "ssh -l litoserv #{host} /bin/ls #{https_dir}"
    output = `#{ssh_cmd}`
    https_files = output.split("\n").sort

    Dir.glob("#{fgdc_current}*.xml").each { |fgdc_file|
      next unless fgdc_file =~ /#{file_pattern}/

      begin
        fgdc_xml = File.read(fgdc_file)
        nokogiri_doc  = Nokogiri::XML(fgdc_xml) do |config|
          config.strict.nonet
        end

        download_link = nokogiri_doc.at_xpath("//idinfo/citation/citeinfo/onlink")
        next unless download_link.present?
        download_link = download_link.text.strip

        # Validate download links in primary http web tree
        if download_link =~ /http:..www.columbia.edu.acis.eds/
          file = download_link.gsub('http://www.columbia.edu/acis/eds/gis/images/', '')
          unless http_files.include?(file)
            puts "ERROR: #{File.basename(fgdc_file)} has bad download link #{download_link}"
          end
        end

        # Validate download links in primary https web tree
        if download_link =~ /https:..www1.columbia.edu.sec.acis.eds/
# puts "found secure link..."
          file = download_link.gsub('https://www1.columbia.edu/sec/acis/eds/dgate/studies/C1301/data/', '')
          unless https_files.include?(file)
            puts "ERROR: #{File.basename(fgdc_file)} has bad download link #{download_link}"
          end
        end

      rescue => ex
        puts "ERROR: #{fgdc_file}: " + ex.message
        # puts "  " + ex.backtrace.select{ |x| x.match(/#{Rails.root}/) }.first
      end
    }

  end

  desc "Validate that OpenGeoServer layer ids are valid"
  task :validate_layers, [:file_pattern] => :environment do |t, args|
    file_pattern = args[:file_pattern] || "."

    capabilities_url = APP_CONFIG['geoserver_url'] +
                       '/sde/ows?service=WFS&request=GetCapabilities'
    capabilities_doc = Nokogiri::XML(open(capabilities_url))

    layer_name_xpath = '//wfs:FeatureTypeList/wfs:FeatureType/wfs:Name'
    all_layer_names = []
    capabilities_doc.xpath(layer_name_xpath).each { |name|
      all_layer_names << name.text.strip
    }

    Dir.glob("#{fgdc_current}*.xml").each { |fgdc_file|
      next unless fgdc_file =~ /#{file_pattern}/

      begin
        fgdc_xml = File.read(fgdc_file)
        fgdc_doc  = Nokogiri::XML(fgdc_xml) do |config|
          config.strict.nonet
        end

        # We only expect public layers to be found in GeoServer
        rights = doc2dc_rights(fgdc_doc)
        next unless rights == 'Public'

        # Raster layers are never loaded to GeoServer
        geom_type = doc2layer_geom_type(fgdc_doc)
        next if geom_type == 'Raster'

        resdesc = fgdc_doc.xpath("//resdesc")
        unless resdesc.present?
          puts "ERROR: public layer #{File.basename(fgdc_file)} missing resdesc"
          next
        end
        resdesc = resdesc.text.strip
        layer_name = "sde:columbia." + resdesc

        unless all_layer_names.include?(layer_name)
          puts "ERROR: public layer #{File.basename(fgdc_file)} has resdesc #{resdesc} not found in GeoServer"
        end

      rescue => ex
        puts "ERROR: #{fgdc_file}: " + ex.message
      end
    }

  end

  desc "Transform the FGDC XML to display HTML"
  task :htmlize, [:file_pattern] => :environment do |t, args|
    file_pattern = args[:file_pattern] || "."

    # If we're doing a full re-generate of all documents, 
    # then delete everything and rebuild from scratch
    if file_pattern == '.'
      FileUtils.rm_rf(fgdc_html_dir)
      FileUtils.mkdir_p(fgdc_html_dir)
    end

    note = " of files matching /#{file_pattern}/" if file_pattern != '.'
    puts "Begining htmlize#{note}..."
    htmlized = 0
    Dir.glob("#{fgdc_current}*.xml").each { |fgdc_file|
      next unless fgdc_file =~ /#{file_pattern}/
      puts " - #{File.basename(fgdc_file)}" if file_pattern != '.'

      begin
        fgdc_xml = File.read(fgdc_file)
        nokogiri_doc  = Nokogiri::XML(fgdc_xml) do |config|
          config.strict.nonet
        end
        # Set some instance variables for repeated reuse
        set_variables(nokogiri_doc)

        fgdc_html = fgdc2html(nokogiri_doc)

        # The HTML file will be name for the FGDC <resdesc> 
        html_file = "#{fgdc_html_dir}#{@resdesc}.html"
        File.write(html_file, fgdc_html + "\n")
        htmlized = htmlized + 1
      rescue => ex
        puts "ERROR: #{fgdc_file}: " + ex.message
        # puts "  " + ex.backtrace.select{ |x| x.match(/#{Rails.root}/) }.first
      end
    }

    puts "Htmlized #{htmlized} files."

  end

  desc "Transform the FGDC XML to GeoBlacklight Schema XML"
  task :transform, [:file_pattern] => :environment do |t, args|
    file_pattern = args[:file_pattern] || "."

    # If we're doing a full re-generate of all documents, 
    # then cycle 'current' to 'old', build new 'current' from scratch.
    if file_pattern == '.'
      FileUtils.rm_rf(geobl_old)
      FileUtils.mv(geobl_current, geobl_old) if File.exists?(geobl_current)
      FileUtils.mkdir_p(geobl_current)
    end

    note = " of files matching /#{file_pattern}/" if file_pattern != '.'
    puts "Begining transform#{note}..."
    transformed = 0
    Dir.glob("#{fgdc_current}*.xml").each { |fgdc_file|
      next unless fgdc_file =~ /#{file_pattern}/

      begin
        puts " - #{File.basename(fgdc_file)}" if file_pattern != '.'
        # The GeoBlacklight schema file will be the same basename, but json
        fgdc_xml = File.read(fgdc_file)


        nokogiri_doc  = Nokogiri::XML(fgdc_xml) do |config|
          config.strict.nonet
        end
        # Set some instance variables for repeated reuse
        set_variables(nokogiri_doc)

        # geobl_json = fgdc2geobl(fgdc_file, fgdc_xml)
        geobl_json = fgdc2geobl(nokogiri_doc)

        # geobl_file = "#{geobl_current}#{File.basename(fgdc_file, '.xml')}.json"
        doc_dir = "#{geobl_current}#{@resdesc}"
        FileUtils.mkdir_p(doc_dir)
        geobl_file = "#{doc_dir}/#{json_filename}"
        File.write(geobl_file, geobl_json + "\n")
        transformed = transformed + 1
      rescue => ex
        puts "ERROR: #{fgdc_file}: " + ex.message
        # puts "  " + ex.backtrace.select{ |x| x.match(/#{Rails.root}/) }.first
      end
    }
    puts "Transformed #{transformed} files."
  end

  desc "Ingest the GeoBlacklight Schema XML"
  task :ingest, [:file_pattern] => :environment do |t, args|
    file_pattern = args[:file_pattern] || "."

    puts "Connecting to Solr..."
    solr = RSolr.connect :url => Blacklight.connection_config[:url]
    puts "solr=#{solr}"

    note = " of files matching /#{file_pattern}/" if file_pattern != '.'
    puts "Begining ingest#{note}..."
    ingested = 0
    Dir.glob("#{geobl_current}*/#{json_filename}").each { |geobl_file|
      next unless geobl_file =~ /#{file_pattern}/

      begin
        # puts " - #{File.basename(geobl_file)}" if file_pattern != '.'
        label = geobl_file.sub(/\/#{json_filename}/, '').sub(/.*\//, '')
        puts " - #{label}" if file_pattern != '.'
        geobl_json = JSON.parse(File.read(geobl_file))
        solr.update params: { commitWithin: 500, overwrite: true },
                    data: [geobl_json].to_json,
                    headers: { 'Content-Type' => 'application/json' }
        ingested = ingested + 1
      rescue => ex
        puts "ERROR: ingesting #{geobl_file}: " + ex.message
        # puts "  " + ex.backtrace.select{ |x| x.match(/#{Rails.root}/) }.first
      end
    }
    puts "Ingested #{ingested} files."

    puts "Committing..."
    solr.update :data => '<commit/>'
    puts "Optimizing..."
    solr.update :data => '<optimize/>'
    puts "Done."

  end

end


