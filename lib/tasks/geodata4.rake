# Rake tasks to build a GeoBlackight 4 Solr instance from FGDC data.
# GeoBlacklight 4 uses the Aardvark metadata schema.

require 'open-uri'
require 'net/ssh'

# require 'fgdc2geobl'
# include Fgdc2Geobl

# require 'fgdc2html'
# include Fgdc2Html

# require 'fgdc2aardvark'
# include Fgdc2Aardvark

# Keep one older iteration - very useful for debugging
tmpdir = '/tmp'
metadata_server = APP_CONFIG['metadata_server'] || abort('metadata_server undefined!')

fgdc_current = File.join(Rails.root, "public/metadata/fgdc/current/")
fgdc_old = File.join(Rails.root, "public/metadata/fgdc/old/")

aardvark_current = File.join(Rails.root, "public/metadata/aardvark/current/")
aardvark_old = File.join(Rails.root, "public/metadata/aardvark/old/")
json_filename = 'aardvark.json'

namespace :aardvark do

  desc "Transform the FGDC XML to Aardvark Schema XML"
  task :transform, [:file_pattern] => :environment do |t, args|
    file_pattern = args[:file_pattern] || "."

    # If we're doing a full re-generate of all documents, 
    # then cycle 'current' to 'old', build new 'current' from scratch.
    if file_pattern == '.'
      FileUtils.rm_rf(aardvark_old)
      FileUtils.mv(aardvark_current, aardvark_old) if File.exists?(aardvark_current)
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
    solr_url = Blacklight.connection_config[:geodata4_url]

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
    puts "Connecting to Solr..."
    solr = RSolr.connect url: Blacklight.connection_config[:geodata4_url]
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

    puts_datestamp "---- metadata:transform ----"
    Rake::Task['aardvark:transform'].execute

    puts_datestamp "---- metadata:ingest ----"
    Rake::Task['aardvark:ingest'].execute

    puts_datestamp "---- metadata:prune_index ----"
    Rake::Task['aardvark:prune_index'].execute

    elapsed_seconds = (Time.now - startTime).round
    min, sec = elapsed_seconds.divmod(60)
    elapsed_note = "(#{min} min, #{sec} sec)"
    puts_datestamp "==== END metadata:process #{elapsed_note} ===="
  end

end

def puts_datestamp(msg)
  puts "#{Time.now}   #{msg}"
end
