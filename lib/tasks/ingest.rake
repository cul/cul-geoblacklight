require 'open-uri'

require 'fgdc2geobl'
include Fgdc2Geobl

# Keep one older iteration - very useful for debugging
geobl_current = File.join(Rails.root, "tmp/metadata/geobl/current/")
fgdc_current = File.join(Rails.root, "tmp/metadata/fgdc/current/")
fgdc_old = File.join(Rails.root, "tmp/metadata/fgdc/old/")
geobl_current = File.join(Rails.root, "tmp/metadata/geobl/current/")
geobl_old = File.join(Rails.root, "tmp/metadata/geobl/old/")

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
    rescue ex
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

  desc "Transform the FGDC XML to GeoBlacklight Schema XML"
  task :transform, [:file_pattern] => :environment do |t, args|
    file_pattern = args[:file_pattern] || "."

    FileUtils.rm_rf(geobl_old)
    FileUtils.mv(geobl_current, geobl_old) if File.exists?(geobl_current)
    FileUtils.mkdir_p(geobl_current)

    Dir.glob("#{fgdc_current}*.xml").each { |fgdc_file|
      next unless fgdc_file =~ /#{file_pattern}/

      begin
        # The GeoBlacklight schema file will be the same basename, but json
        geobl_file = "#{geobl_current}#{File.basename(fgdc_file, '.xml')}.json"
        fgdc_xml = File.read(fgdc_file)
        geobl_json = fgdc2geobl(fgdc_xml)
        File.write(geobl_file, geobl_json + "\n")
      rescue => ex
        puts "Error processing #{fgdc_file}: " + ex.message
        puts "  " + ex.backtrace.select{ |x| x.match(/#{Rails.root}/) }.first
      end
    }
  end

  desc "Ingest the GeoBlacklight Schema XML"
  task :ingest => :environment do
  end
end


