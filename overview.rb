# for all codebases in the given folder, git fetch and list all commits for the last time period

require 'git'

if ARGV.size != 3 && ARGV.size != 4
  puts ARGV
  puts "USAGE: ruby overview.rb /Users/me/repositories/foo/ all 1days --with-commits"
  puts "USAGE: ruby overview.rb /Users/me/repositories/foo/ all 3days"
  puts "USAGE: ruby overview.rb /Users/me/repositories/foo/ all 1weeks"
  puts "USAGE: ruby overview.rb /Users/me/repositories/foo/ ice-menu-api,menu-bff,sonic-flagship-ios 2weeks"
  exit
end

root_dir = ARGV[0]
dapis = ARGV[1]
duration = ARGV[2]
show_commits = ARGV[3] == "--with-commits" # this is a total hack of a way to use commandline flags, use https://rubygems.org/gems/trollop (or something similar) instead

puts "root_dir: #{root_dir}"
puts "dapis: #{dapis}"
puts "duration: #{duration}"
puts "show_commits: #{show_commits}"
puts ""


if dapis == "all"
  potential_repos = Dir.entries(root_dir).select {|entry| File.directory? File.join(root_dir, entry) and !(entry =='.' || entry == '..')}.map {|d| root_dir + d}
else
  potential_repos = dapis.split(",").map {|d| root_dir + d}
end

if duration.include?("days")
  g_duration = duration.gsub("days", " days ago")
elsif duration.include?("weeks")
  g_duration = duration.gsub("weeks", " weeks ago")
else
  puts "Can't figure out duration #{duration}. Try one of these: 1days 3days 1weeks 2weeks"
  exit
end

maximum_commits_to_parse = 200 # defaults to 30

potential_repos.each {|r|
  puts ""
  begin
    g = Git.open(r)
    g.fetch
    commits = g.log(maximum_commits_to_parse).since(g_duration)
    names = []
    commits.each {|c|
      if match = c.message.match(/.*\[(.*)\].*/)
        names << match.captures.first.split(",").map(&:strip)
      else
        names << c.author.name
      end
    }
    developers = names.flatten.uniq.sort.join(", ")

    puts "#{r}"
    puts "#{commits.count} commits since #{g_duration} by: #{developers}"

    if show_commits
      puts commits.map(&:message)
    end
  rescue => e
    puts "Can't get metrics for #{r} because of error: #{e.message}"
  end
}
