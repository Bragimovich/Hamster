log = File.read("#{ENV['HOME']}/locallabs/companies.log")

log = log.gsub(%r{\e\[0[\d]*;?\d{0,2}m}m, '')
hashes = log.split(/}[-\w\n\t\s]+{/)

hashes[0] = hashes[0].gsub(/^[-+:\w\s]+{\n/m, '')
hashes[-1] = hashes[-1].gsub(/\n}/, '')
counts = {}
hashes.map do |e|
  e.split(",\n").map do |p|
    p = p.strip.split(' => ')
    [p[0].sub(/:/, '').to_sym, p[1].gsub(/"/, '')]
    counts[p.first] ||= 0
    counts[p.first]  += 1
  end
end

counts.each { |e| e[0] = e[0].sub(/:/, ''); puts "#{e.first},#{e.last}" }

p counts
