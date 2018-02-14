
# Rake tasks for ingesting other institution's layers
# from https://github.com/OpenGeoMetadata

namespace :opengeometadata do
  commit_within = (ENV['SOLR_COMMIT_WITHIN'] || 5000).to_i
  ogm_path = ENV['OGM_PATH'] || 'tmp/opengeometadata'
  solr_url = ENV['SOLR_URL']

  repos = [
    'edu.stanford.purl',
    'edu.nyu',
    'edu.virginia',
  ]

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

    puts "[#{ogm_path}/#{repo}]"

    Find.find("#{ogm_path}/#{repo}") do |path|
      next unless File.basename(path) == 'geoblacklight.json'
      doc = JSON.parse(File.read(path))
      [doc].flatten.each do |record|
        begin
          # GEO-26 - Suppress restricted layers
          next if record['dc_rights_s'] == 'Restricted'

          puts "Indexing #{record['layer_slug_s']}: #{path}" if $DEBUG
          solr.update params: { commitWithin: commit_within, overwrite: true },
                      data: [record].to_json,
                      headers: { 'Content-Type' => 'application/json' }
        rescue RSolr::Error::Http => error
          puts error
        end
      end
    end
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
# multiple provenances (e.g., [ "NYU", "Baruch CUNY"]),
# 
# 
def getRepoProvenances(repo)
  case repo
  when 'edu.stanford.purl'
    return 'Stanford'
  when 'edu.virginia'
    return 'UVa'
  when 'edu.nyu'
    return [ 'NYU', 'Baruch CUNY' ]
  else
    raise "ERROR:  Unknown provenance for repo #{repo}"
  end
end


