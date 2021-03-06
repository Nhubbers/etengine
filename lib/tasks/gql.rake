require 'open-uri'

namespace :g do
  task :f do Rake::Task["gql:future"].invoke; end
  task :p do Rake::Task["gql:present"].invoke; end
end

namespace :gql do

  namespace :check do
    desc 'Check if inputs run.'
    task :inputs => :environment do
      init_environment
      exceptions = {}

      gql = unprepared_gql
      Input.all.each do |input|
        begin
          gql.update_graph(gql.future, input, 3.0)
        rescue => e
          exceptions[input] = e
        end
      end

      puts "=" * 20
      if exceptions.empty?
        puts "All inputs completed"
      else
        exceptions.each do |input, e|
          puts "# #{input.key}"
          puts e.message
          puts "-" * 20
        end
        puts "=" * 20
        puts "Failed: #{exceptions.keys.map(&:key).join(', ')}"
      end
    end

    desc 'Check if gqueries run.'
    task :gqueries => :environment do
      init_environment
      exceptions = {}

      gql = prepared_gql
      Gquery.all.each do |gquery|
        begin
          gql.query(gquery)
        rescue => e
          exceptions[gquery] = e
        end
      end

      puts "=" * 20
      if exceptions.empty?
        puts "All inputs completed"
      else
        exceptions.each do |gquery, e|
          puts "# #{gquery.key}"
          puts e.message
          puts "-" * 20
        end
        puts "=" * 20
        puts "Failed: #{exceptions.keys.map(&:key).join(', ')}"
      end
    end
  end

  desc 'GQL Console for future (alias g:f)'
  task :future => :environment do
    init_environment
    prepared_gql.future.rubel.console
  end

  desc 'GQL Console for present (alias g:p)'
  task :present => :environment do
    init_environment
    prepared_gql.present.rubel.console
  end

  desc 'GQL Console that allows to run update statements.'
  task :debug => :environment do
    init_environment
    prepared_gql(:debug => true).future.rubel.console
  end

  desc 'Run all turk files'
  task :test => :environment do
    if filepath = ENV['FILE']
      MechanicalTurk::Turk.new(filepath).run
    else
      MechanicalTurk::Turk.all.each(&:run)
    end
  end

  namespace :test do
    desc 'Update turk files (for other areas use AREA_CODE=nl)'
    task :update => :environment do
      init_environment

      output_path     = "spec/mechanical_turk/generated"
      # output_path     = Etsource::Base.instance.base_dir+"/mechanical_turk/generated"

      Dir.glob(output_path+"/scenario_definitions/*.yml").each do |yml_file|
        puts "** Updating: #{yml_file}"
        path      = Pathname.new(yml_file)

        settings  = YAML::load_file(yml_file).with_indifferent_access
        response  = Api::V2::Request.response(settings.merge(id: 'test').dup).response

        file_path = output_path+"/#{path.basename.to_s.split('.').first}_spec.rb"
        File.open(file_path, 'w') do |f|
          f.write MechanicalTurk::Generator.new(response.to_json, :all).render
        end
      end
    end
  end

  task :performance => :environment do
    init_environment
    g = gql
    Gquery.all.each do |gquery|
      begin
        puts gquery.key
        g.query(gquery)
      rescue => e
        puts 'rescue'
      end
    end
  end

  desc 'Dump a dataset for debugging datasets.'
  task :dataset => :environment do
    gql = unprepared_gql
    hsh = Etsource::Loader.instance.raw_hash(gql.scenario.area_code)
    puts YAML::dump(hsh)
  end

  def init_environment
    GC.disable
    Rails.cache.clear
    # Use etsource git repository per default
    # Use different directory by passing ETSOURCE_DIR=...
    unless ENV['ETSOURCE_DIR']
      Etsource::Base.loader(ETSOURCE_DIR)
    end

    puts "** Using: #{Etsource::Base.instance.export_dir}"
  end

  def prepared_gql(options = {})
    gql = unprepared_gql
    gql.future.rubel.pry if options[:debug] == true
    gql.prepare
    gql.sandbox_mode = :console
    gql
  end

  # Loads the gql.
  def unprepared_gql
    NastyCache.instance.expire!

    gql = load_scenario.gql(prepare: false)
    gql.sandbox_mode = :console
    gql.init_datasets
    # omit gql.prepare
    # omit gql.calculate
    gql
  end

  def load_scenario
    if settings = load_settings
      settings = settings[:settings].with_indifferent_access
      scenario = Scenario.new(Scenario.new_attributes(settings))
    else
      scenario = Scenario.default
    end
  end

  def load_settings
    json_file = ENV['JSON'] || "tmp/default.json"
    settings = JSON.parse(open(json_file).read) rescue nil
    if settings
      puts "** Using settings defined in #{json_file}"
      puts "** #{settings['settings']}"
      settings and settings.with_indifferent_access
    else
      puts "** Using default scenario"
      nil
    end
  end
end
