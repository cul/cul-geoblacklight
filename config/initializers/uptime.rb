
BOOTED_AT = Time.now

LAST_DEPLOYED = File.atime(Dir.pwd).to_s(:long)

GEODATA_VERSION = IO.read('VERSION').strip

