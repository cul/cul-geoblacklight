
# Rake tasks for ingesting other institution's layers
# from https://github.com/OpenGeoMetadata

namespace :opengeometadata do
  commit_within = (ENV['SOLR_COMMIT_WITHIN'] || 5000).to_i
  ogm_path = ENV['OGM_PATH'] || 'tmp/opengeometadata'
  solr_url = ENV['SOLR_URL']

  core_repos = [
    'edu.stanford.purl',
    'edu.nyu',
    'edu.virginia',
    'big-ten',
  ]

  repos = APP_CONFIG['opengeometadata_repos'] || core_repos
  
  desc "Download OpenGeoMetadata for all configured institutions"
  task :fetch_all=> :environment do
    puts_datestamp "---- metadata:fetch_all ----"
    repos.each do |repo|
      printf("-- Updating %s --\n", repo)
      Rake::Task["opengeometadata:fetch"].reenable
      Rake::Task["opengeometadata:fetch"].invoke(repo)
    end
  end

  desc 'Fetch a single OpenGeoMetadata repo (create or update)'
  task :fetch, [:repo] => :environment do |t, args|
    unless repo = args[:repo]
      puts "Must pass input arg :repo (e.g.: rake opengeometadata:fetch[edu.nyu])" 
      next
    end
    github = "https://github.com/OpenGeoMetadata/#{repo}.git"

    FileUtils.mkdir_p(ogm_path)

    if Dir.exist?("#{ogm_path}/#{repo}")
      puts "Pulling #{repo}"
      system "cd #{ogm_path}/#{repo} && git pull origin"
    else
      puts "Cloning #{repo}"
      system "cd #{ogm_path} && git clone --depth 1 #{github}"
    end
  end
  


  # Some OpenGeoMetadata repos provide FGDC, not GeoBlacklight JSON
  desc "Transform OpenGeoMetadata FGDC XML to GeoBlacklight Schema JSON"
  task :transform, [:repo] => :environment do |t, args|
    unless repo = args[:repo]
      puts "Must pass input arg :repo (e.g.: rake opengeometadata:transform[edu.tufts])" 
      next
    end

    unless Dir.exist?("#{ogm_path}/#{repo}")
      puts "ERROR: Cannot not find directory #{ogm_path}/#{repo}" 
      next
    end

    puts "Begining transform..."
    transformed = 0
    Find.find("#{ogm_path}/#{repo}") do |fgdc_file|
      next unless File.basename(fgdc_file) == 'fgdc.xml'

      begin
        # The GeoBlacklight schema file will be the same basename, but json
        fgdc_xml = File.read(fgdc_file)
        nokogiri_doc  = Nokogiri::XML(fgdc_xml) do |config|
          config.strict.nonet
        end
        # Parse doc to set @key, etc.
        set_variables(repo, nokogiri_doc)

        # Need the original funky XML filename, as well as the nokogiri doc
        geobl_json = fgdc2geobl(fgdc_file, nokogiri_doc)

        doc_dir = File.dirname(fgdc_file)
        geobl_file = "#{doc_dir}/geoblacklight.json"
        File.write(geobl_file, geobl_json + "\n")
        transformed = transformed + 1
      rescue => ex
        puts "ERROR: #{fgdc_file}: " + ex.message
        # puts "  " + ex.backtrace.select{ |x| x.match(/#{Rails.root}/) }.first
      end
    end
    puts "Transformed #{transformed} files."
  end




  
  desc "Ingest OpenGeoMetadata for all configured institutions"
  task :ingest_all=> :environment do
    puts_datestamp "---- metadata:ingest_all ----"
    repos.each do |repo|
      printf("-- Ingesting %s --\n", repo)
      Rake::Task["opengeometadata:ingest"].reenable
      Rake::Task["opengeometadata:ingest"].invoke(repo)
    end
  end

  desc 'Ingest a single OpenGeoMetadata repo'
  task :ingest, [:repo] => :environment do |t, args|
    unless repo = args[:repo]
      puts "Must pass input arg :repo (e.g.: rake opengeometadata:ingest[edu.nyu])" 
      next
    end

    puts "Ingesting #{repo}"
    unless Dir.exist?("#{ogm_path}/#{repo}")
      puts "ERROR: Cannot not find directory #{ogm_path}/#{repo}" 
      next
    end

    puts "Connecting to Solr..."
    solr = RSolr.connect :url => Blacklight.connection_config[:url]
    puts "solr=#{solr}"

    puts "local repo path:  #{ogm_path}/#{repo}"

    found = 0
    restricted = 0
    ingested = 0
    Find.find("#{ogm_path}/#{repo}") do |path|
      next unless File.basename(path) == 'geoblacklight.json'
      found = found + 1
      doc = JSON.parse(File.read(path))
      [doc].flatten.each do |record|
        begin
          # GEO-26 - Suppress restricted layers
          if record['dc_rights_s'] == 'Restricted'
            restricted = restricted + 1
            next
          end
          
          # Skip out-of-bounds ENVELOPE() data
          if not valid_geometry?(record['solr_geom'])
            puts "ERROR: layer id #{record['layer_id_s']} solr_geom data NOT valid:  #{record['solr_geom']}"
            next
          end

          puts "Indexing #{record['layer_slug_s']}: #{path}" if $DEBUG
          solr.update params: { commitWithin: commit_within, overwrite: true },
                      data: [record].to_json,
                      headers: { 'Content-Type' => 'application/json' }
          ingested = ingested + 1
        rescue RSolr::Error::Http => error
          puts error
        end
      end
    end
    puts "Found #{found} layers total, #{restricted} restricted, ingested #{ingested}."
    solr.commit
  end

  desc "Prune stale OpenGeoMetadata records for all configured institutions"
  task :prune_all=> :environment do
    puts_datestamp "---- metadata:prune_all ----"
    repos.each do |repo|
      printf("-- Pruning %s\n", repo)
      Rake::Task["opengeometadata:prune"].reenable
      Rake::Task["opengeometadata:prune"].invoke(repo)
    end
  end


  desc "Delete stale records from the Solr search index"
  task :prune, [:repo] => :environment do |t, args|
    unless repo = args[:repo]
      puts "Must pass input arg :repo (e.g.: rake opengeometadata:prune[edu.nyu])" 
      next
    end

    puts "Pruning stale records for #{repo}..."

    puts "Connecting to Solr..."
    solr = RSolr.connect url: Blacklight.connection_config[:url]
    puts "solr=#{solr}"

    provenances = getRepoProvenances(repo)

    Array(provenances).each do |provenance|
      stale = (ENV['STALE_DAYS'] || 21).to_i
      query = "timestamp:[* TO NOW/DAY-#{stale}DAYS] AND dct_provenance_s:\"#{provenance}\""

      puts "Pruning #{provenance}..."
      puts "(#{query})"
      solr.delete_by_query query
    end

    puts "Committing..."
    solr.commit
    puts "Optimizing..."
    solr.optimize
    puts "Done."
  end

  desc "Download, Ingest, and Prune OpenGeoMetadata for all institutions"
  task :process => :environment do
    startTime = Time.now
    puts_datestamp "==== START opengeometadata:process ===="

    repos.each do |repo|
      Rake::Task["opengeometadata:fetch_all"].invoke
      Rake::Task["opengeometadata:ingest_all"].invoke
      Rake::Task["opengeometadata:prune_all"].invoke
    end

    elapsed_seconds = (Time.now - startTime).round
    min, sec = elapsed_seconds.divmod(60)
    elapsed_note = "(#{min} min, #{sec} sec)"
    puts_datestamp "==== END metadata:process #{elapsed_note} ===="
  end
  
end


def puts_datestamp(msg)
  puts "#{Time.now}   #{msg}"
end


# A given repo (e.g., NYU) may contain metadata records from
# multiple provenances (e.g., [ "NYU", "Baruch CUNY"]).
# We'll hard-code this mapping for now, but we should really
# extract possible provenance values from the supplied data.
# 
def getRepoProvenances(repo)
  case repo
  when 'big-ten'
    # The "Big Ten" is an alliance of 14 [sic] institutions.
    # Only 9 of them contribute records to OpenGeoMetadata currently.
    [ 'Illinois', 'Indiana', 'Iowa', 'Maryland', 'Michigan',
      'Michigan State', 'Minnesota', 'Purdue', 'Wisconsin' ]
  when 'edu.berkeley'
    return 'Berkeley'
  when 'edu.cornell'
    return 'Cornell'
  when 'edu.harvard'
    return 'Harvard'
  when 'edu.nyu'
    return [ 'NYU', 'Baruch CUNY' ]
  when 'edu.princeton.arks'
    return 'Princeton'
  when 'edu.stanford.purl'
    return 'Stanford'
  when 'edu.tufts'
    return 'Tufts'
  when 'edu.virginia'
    return 'UVa'
  else
    raise "ERROR:  Unknown provenance for repo #{repo}"
  end
end

# Is the passed geometry valid?
def valid_geometry?(solr_geom)
  return false unless solr_geom.present?

  # :solr_geom  => "ENVELOPE(#{w}, #{e}, #{n}, #{s})",
  # Solr docs say:   "minX, maxX, maxY, minY order"
  # maximum boundary: (minX=-180.0,maxX=180.0,minY=-90.0,maxY=90.0)
  match = solr_geom.match(/ENVELOPE\(([\d\.\-]+), ([\d\.\-]+), ([\d\.\-]+), ([\d\.\-]+)\)/)

  # Not parsable ENVELOPE() syntax?
  return false unless match.present?

  minX, maxX, maxY, minY = match.captures
  return false if minX.to_f < -180 ||
                  maxX.to_f >  180 ||
                  maxY.to_f >   90 ||
                  minY.to_f <  -90

  return true
end



