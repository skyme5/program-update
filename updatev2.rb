require 'json'

require 'http'
require 'colorize'


META_FILE_NAME = File.join(__dir__,'watch.info.json')
LIST_FILE_NAME = File.join(__dir__,'watch.json')

FORCE_UPDATE = ARGV.include?('-f')

$llength = 0
def log(s, newline=false)
	$llength = s.length if $llength < s.length
	print "#{s.ljust($llength, ' ')}" + (newline ? "\n" : '') + "\r"
end

def _read_json(filepath)
	JSON.parse(File.read(filepath))
end

def _write_json(filepath, data)
	out = File.open(filepath, 'w')
	out.puts data.to_json
	out.close
end

$meta_info = _read_json(META_FILE_NAME)

def is_new_version(repo, new_id)
	meta = $meta_info[repo]
	return [true, "0.0.0"] unless $meta_info.key?(repo)

	is_update = FORCE_UPDATE ? true : meta["id"] != new_id

	return [is_update, meta["tag_name"]]
end

def update_meta_info(repo, id, name, tag_name)
	data = _read_json(META_FILE_NAME)
	data[repo] = { "id": id, "name": name, "tag_name": tag_name}
	_write_json(META_FILE_NAME, data)
end

packages = JSON.parse(File.read(LIST_FILE_NAME))

packages.each do |package|
	program = package["program"]

	api_response = JSON.parse(HTTP.get("https://api.github.com/repos/#{package["repo"]}/releases").to_s)
	latest_release = api_response.first

	release_id = latest_release["id"]
	release_tagname = latest_release["tag_name"]

	is_update, old_tagname = is_new_version(package["repo"], release_id)

	log("#{program.white} [#{old_tagname.cyan}] is upto date.", true) unless is_update
	next unless is_update

	log("Updating #{program} ... ")

	target = latest_release["assets"].select { |release|
		Regexp.new(package["name"]).match(release["name"])
	}

	download_url = target.first["browser_download_url"]
	download_name = target.first["name"]

	log("Updating #{program.yellow} ... downloading #{download_url.yellow}")

	system("wget -q \"#{download_url}\" -O #{File.join(__dir__, "packages", program)}.#{download_name.split('.').last}")

	log("Updating #{program.yellow} ... extracting ...")

	if system(package["cmd"].gsub("{PATH}", File.join(__dir__, 'packages')))
		log("#{program} updated! (#{old_tagname.cyan} -> #{release_tagname.green})", true)
		update_meta_info(package["repo"], release_id, download_name, release_tagname)
	end
end
