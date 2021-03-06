namespace :db do
  task "seeds:fetch", %s(debug) do |t, args|
    args.with_defaults(debug: ENV["DEBUG"])
    puts "fetching over the wire"
    conn = Faraday.new(url: "https://raw.githubusercontent.com") do |c|
      c.use Faraday::Response::Logger if args.debug
      c.use Faraday::Adapter::NetHttp
    end

    %w(schema migrations seeds).each do |file|
      response = conn.get do |req|
        req.url "/exercism/seeds/master/db/#{file}.sql"
        req.headers['User-Agent'] = "github.com/exercism/exercism.io"
      end
      File.open("./db/#{file}.sql", 'w') do |f|
        f.write response.body
      end
    end
  end

  desc "generate seed data"
  task :seed do
    require 'bundler'
    Bundler.require
    require 'exercism'

    %x{dropdb exercism_development -U exercism}
    %x{createdb -O exercism exercism_development -U exercism}
    Rake::Task['db:seeds:fetch'].invoke
    %w(schema migrations seeds).each do |file|
      %x{psql -U exercism -d exercism_development -f db/#{file}.sql}
    end

    # Trigger generation of html body
    Comment.find_each { |comment| comment.save }
  end

  desc "add recently viewed data for a specific (test) user by username"
  task "seed:looks", [:username, :count] do |t, args|
    if args[:username].nil?
      puts "USAGE: rake db:seed:looks[username]\n   OR: rake db:seed:looks[username,count]"
      exit 1
    end

    require 'bundler'
    Bundler.require
    require 'exercism'

    count = args[:count] || 25
    user = User.find_by_username(args[:username])
    if user.nil?
      puts "Unable to find user with username '#{args[:username]}'"
      exit 1
    end

    UserExercise.order('created_at DESC').limit(count).pluck(:id).each do |id|
      Look.check!(id, user.id)
    end
  end
end
