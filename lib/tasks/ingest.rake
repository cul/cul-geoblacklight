# Rake tasks to build a GeoBlackight 4 Solr instance from FGDC data.
# GeoBlacklight 4 uses the Aardvark metadata schema.

require 'open-uri'
require 'net/ssh'

# require 'fgdc2geobl'
# include Fgdc2Geobl

# require 'fgdc2html'
# include Fgdc2Html

require 'fgdc2aardvark'
include Fgdc2Aardvark

require 'fgdc_helpers'
include FgdcHelpers

# Keep one older iteration - very useful for debugging
tmpdir = '/tmp'
metadata_server = APP_CONFIG['metadata_server'] || abort('metadata_server undefined!')

fgdc_current = File.join(Rails.root, "public/metadata/fgdc/current/")
fgdc_old = File.join(Rails.root, "public/metadata/fgdc/old/")

aardvark_current = File.join(Rails.root, "public/metadata/aardvark/current/")
aardvark_old = File.join(Rails.root, "public/metadata/aardvark/old/")
json_filename = 'aardvark.json'

namespace :metadata do

desc "Download the FGDC XML"
  task :download => :environment do
    FGDC_METADATA_URL = APP_CONFIG['fgdc_metadata_url']

    begin
      puts "Downloading #{FGDC_METADATA_URL}..."
      download = URI.open(FGDC_METADATA_URL)
      IO.copy_stream(download, "#{tmpdir}/metadata.zip")
      puts "Download successful."
    rescue => ex
      puts "Download unsuccessful:  #{ex}"
      next
    end

    # puts "Comparing to previous download..."
    old_file_size = File.size("#{fgdc_current}/metadata.zip")
    new_file_size = File.size("#{tmpdir}/metadata.zip")
    # puts "old_file_size=[#{old_file_size}]"
    # puts "new_file_size=[#{new_file_size}]"
    diff = (new_file_size - old_file_size).to_f
    delta = ((diff / old_file_size) * 100).to_i
    # puts "delta=[#{delta}]"
    puts "New metadata file size is #{delta}% change from previous file size."
    
    diff = (ENV['FGDC_DIFF'] || 10).to_i
    if delta.abs > diff
      puts "ERROR: percentage difference (#{delta}%) greater than limit (#{diff}%)"
      puts "Use environment variable $FGDC_DIFF to override diff percentage threshold."
      abort "Aborting."
    end

    puts "Moving metadata.zip to #{fgdc_current}..."

    FileUtils.rm_rf(fgdc_old)
    FileUtils.mv(fgdc_current, fgdc_old) if File.exist?(fgdc_current)
    FileUtils.mkdir_p(fgdc_current)
    FileUtils.mv("#{tmpdir}/metadata.zip", "#{fgdc_current}/metadata.zip")

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

    ssh_cmd = "ssh -q -l litoserv #{host} /bin/ls #{http_dir}"
    output = `#{ssh_cmd}`
    http_files = output.split("\n").sort

    ssh_cmd = "ssh -q -l litoserv #{host} /bin/ls #{https_dir}"
    output = `#{ssh_cmd}`
    https_files = output.split("\n").sort

    Dir.glob("#{fgdc_current}*.xml").each { |fgdc_file|
      next unless fgdc_file =~ /#{file_pattern}/
      fgdc_basename = File.basename(fgdc_file)

      begin
        fgdc_xml = File.read(fgdc_file)
        nokogiri_doc  = Nokogiri::XML(fgdc_xml) do |config|
          config.strict.nonet
        end
        # Parse doc to set @key, etc.
        set_variables('edu.columbia', nokogiri_doc)

        download_link = nokogiri_doc.at_xpath("//idinfo/citation/citeinfo/onlink")
        next unless download_link.present?
        download_link = download_link.text.strip

        # Validate download links in primary http web tree
        if download_link =~ /http:..www.columbia.edu.acis.eds/
          file = download_link.gsub('http://www.columbia.edu/acis/eds/gis/images/', '')
          unless http_files.include?(file)
            puts "ERROR: #{fgdc_basename} has bad download link #{download_link}"
          end
        end

        # Validate download links in primary https web tree
        if download_link =~ /https:..www1.columbia.edu.sec.acis.eds/
# puts "found secure link..."
          file = download_link.gsub('https://www1.columbia.edu/sec/acis/eds/dgate/studies/C1301/data/', '')
          unless https_files.include?(file)
            puts "ERROR: #{fgdc_basename} has bad download link #{download_link}"
          end
        end

      rescue => ex
        puts "ERROR: #{fgdc_file}: " + ex.message
        puts "  " + ex.backtrace.select{ |x| x.match(/#{Rails.root}/) }.first
      end
    }

  end

  desc "Validate that OpenGeoServer layer ids are valid"
  task :validate_layers, [:file_pattern] => :environment do |t, args|
    file_pattern = args[:file_pattern] || "."

    capabilities_url = APP_CONFIG['geoserver_url'] +
                       '/sde/ows?service=WFS&request=GetCapabilities'
    capabilities_doc = Nokogiri::XML(URI.open(capabilities_url))

    layer_name_xpath = '//wfs:FeatureTypeList/wfs:FeatureType/wfs:Name'
    all_layer_names = []
    capabilities_doc.xpath(layer_name_xpath).each { |name|
      all_layer_names << name.text.strip
    }

    # Track resdesc-to-FGDC mapping, to detect duplicate resdescs
    resdesc_map = {}

    Dir.glob("#{fgdc_current}*.xml").each { |fgdc_file|
      # puts "fgdc_file: #{fgdc_file}" if ENV['DEBUG']
      next unless fgdc_file =~ /#{file_pattern}/
      fgdc_basename = File.basename(fgdc_file)
      puts "validating fgdc_basename: #{fgdc_basename}" if ENV['DEBUG']

      begin
        fgdc_xml = File.read(fgdc_file)
        nokogiri_doc  = Nokogiri::XML(fgdc_xml) do |config|
          config.strict.nonet
        end
        # Parse doc to set @key, etc.
        set_variables('edu.columbia', nokogiri_doc)
        if @key.match /[^\w\-]/
          puts "ERROR: resdesc '#{@key}' contains invalid character(s)  (#{fgdc_basename})"
          next
        end

        if resdesc_map[@key].present?
          puts "ERROR: resdesc '#{@key}' used in both #{fgdc_basename} and #{resdesc_map[@key]}"
          next
        else
          resdesc_map[@key] = fgdc_basename
        end

        # We only expect public layers to be found in GeoServer
        rights = doc2dct_rights_sm(nokogiri_doc)
        next unless rights == 'Public'

        # Raster layers are never loaded to GeoServer
        geom_type = doc2gbl_resourceType_sm(nokogiri_doc)
        puts "geom_type: #{geom_type}" if ENV['DEBUG']
        next if geom_type == 'Raster'

        unless @key.present?
          puts "ERROR: public layer #{fgdc_basename} missing resdesc"
          next
        end
        layer_name = "sde:columbia." + @key

        unless all_layer_names.include?(layer_name)
          puts "ERROR: resdesc '#{@key}' (#{layer_name}) not found in GeoServer (#{fgdc_basename})"
        end

      rescue => ex
        puts "ERROR: #{fgdc_file}: " + ex.message
      end
    }

  end

  desc "Transform the FGDC XML to Aardvark Schema XML"
  task :transform, [:file_pattern] => :environment do |t, args|
    file_pattern = args[:file_pattern] || "."

    # If we're doing a full re-generate of all documents, 
    # then cycle 'current' to 'old', build new 'current' from scratch.
    if file_pattern == '.'
      FileUtils.rm_rf(aardvark_old)
      FileUtils.mv(aardvark_current, aardvark_old) if File.exist?(aardvark_current)
      FileUtils.mkdir_p(aardvark_current)
    end

    note = " of files matching /#{file_pattern}/" if file_pattern != '.'
    puts "Begining transform#{note}..."
    transformed = 0
    Dir.glob("#{fgdc_current}*.xml").each { |fgdc_file|
      next unless fgdc_file =~ /#{file_pattern}/
      fgdc_basename = File.basename(fgdc_file)

      begin
        puts " - #{fgdc_basename}" if file_pattern != '.'
        # The Aardvark schema file will be the same basename, but json
        fgdc_xml = File.read(fgdc_file)
        nokogiri_doc  = Nokogiri::XML(fgdc_xml) do |config|
          config.strict.nonet
        end
        # Parse doc to set @key, etc.
        set_variables('edu.columbia', nokogiri_doc)

        # Need public URL to the FGDC XML file, as well as the nokogiri doc
        fgdc_url = metadata_server + fgdc_file.gsub(/.*metadata/, '/metadata')
        aardvark_json = fgdc2aardvark(fgdc_url, nokogiri_doc)

        doc_dir = "#{aardvark_current}#{@key}"
        FileUtils.mkdir_p(doc_dir)
        aardvark_file = "#{doc_dir}/#{json_filename}"
        File.write(aardvark_file, aardvark_json + "\n")
        transformed = transformed + 1
      rescue => ex
        puts "ERROR: #{fgdc_file}: " + ex.message
        puts "  " + ex.backtrace.select{ |x| x.match(/#{Rails.root}/) }.first
      end
    }
    puts "Transformed #{transformed} files."
  end

  desc "Ingest the Aardvark Schema XML"
  task :ingest, [:file_pattern] => :environment do |t, args|
    file_pattern = args[:file_pattern] || "."
    solr_url = Blacklight.connection_config[:url]

    puts "Connecting to Solr (#{solr_url})..."
    solr = RSolr.connect url: solr_url
    puts "solr=#{solr}"

    note = " of files matching /#{file_pattern}/" if file_pattern != '.'
    puts "Begining ingest#{note}..."
    ingested = 0
    Dir.glob("#{aardvark_current}*/#{json_filename}").each { |aardvark_file|
      next unless aardvark_file =~ /#{file_pattern}/

      begin
        label = aardvark_file.sub(/\/#{json_filename}/, '').sub(/.*\//, '')
        puts " - #{label}" if file_pattern != '.'
        aardvark_json = JSON.parse(File.read(aardvark_file))
        solr.update params: { commitWithin: 500, overwrite: true },
                    data: [aardvark_json].to_json,
                    headers: { 'Content-Type' => 'application/json' }
        ingested = ingested + 1
      rescue => ex
        puts "ERROR: ingesting #{aardvark_file}: " + ex.message
        puts "  " + ex.backtrace.select{ |x| x.match(/#{Rails.root}/) }.first
      end
    }
    puts "Ingested #{ingested} files."

    puts "Committing..."
    solr.commit
    # no, optimize only after deletes, not after adds
    # puts "Optimizing..."
    # solr.optimize
    puts "Done."
  end
  
  desc "Delete stale records from the Solr search index"
  task :prune_index => :environment do
    solr_url = Blacklight.connection_config[:url]
    puts "Connecting to Solr (#{solr_url})..."
    solr = RSolr.connect url: solr_url
    puts "solr=#{solr}"

    if ENV['STALE_DAYS'] && ENV['STALE_DAYS'].to_i < 2
      puts "ERROR: Environment variable STALE_DAYS set to [#{ENV['STALE_DAYS']}]"
      puts "ERROR: Should be > 1, or unset to allow default setting."
      puts "ERROR: Skipping prune_index step."
      next
    end

    stale = (ENV['STALE_DAYS'] || 21).to_i
    query = "timestamp:[* TO NOW/DAY-#{stale}DAYS] AND schema_provider_s:Columbia"

    puts "Pruning..."
    puts "(#{query})"
    solr.delete_by_query query

    puts "Committing..."
    solr.commit
    puts "Optimizing..."
    begin
      solr.optimize
    rescue RSolr::Error::Http, Faraday::TimeoutError, Net::ReadTimeout
      # no-op
    end
    puts "Done."
  end

  desc "Download, Validate, Transform, and Ingest Metadata"
  task :process => :environment do
    startTime = Time.now
    puts_datestamp "==== START metadata:process ===="

    puts_datestamp "---- metadata:download ----"
    Rake::Task['metadata:download'].execute

    puts_datestamp "---- metadata:validate_downloads ----"
    Rake::Task['metadata:validate_downloads'].execute

    puts_datestamp "---- metadata:validate_layers ----"
    Rake::Task['metadata:validate_layers'].execute

    puts_datestamp "---- metadata:transform ----"
    Rake::Task['metadata:transform'].execute

    puts_datestamp "---- metadata:ingest ----"
    Rake::Task['metadata:ingest'].execute

    puts_datestamp "---- metadata:prune_index ----"
    Rake::Task['metadata:prune_index'].execute

    elapsed_seconds = (Time.now - startTime).round
    min, sec = elapsed_seconds.divmod(60)
    elapsed_note = "(#{min} min, #{sec} sec)"
    puts_datestamp "==== END metadata:process #{elapsed_note} ===="
  end

end

def puts_datestamp(msg)
  puts "#{Time.now}   #{msg}"
end
