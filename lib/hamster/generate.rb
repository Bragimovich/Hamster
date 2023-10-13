# hamster scafold command 
# ruby hamster.rb --generate=NNNN --scafold
# ruby hamster.rb --generate=NNNN --model
module Hamster
  private

  def self.generate(args)
    check_project_number(:generate)
    
    @project_number = project_number
    model(@project_number) if args.key?(:model)
    scaffold(@project_number) if args.key?(:scaffold)
  end

  def self.scaffold(project_number)
    s   = Storage.new
    template_files = ["keeper.rb", "manager.rb", "parser.rb","scraper.rb"]
    directory_path = Dir["#{s.project}s/*"].find { |d| d[project_number] }

    puts "Project #{project_number} not found".red if directory_path.nil?

    return if directory_path.nil?

    lib_files = Dir[directory_path + "/lib/*"]
    lib_file_names_without_path = lib_files.map{|x| x.split("/").last}

    ARGV.clear

    template_files.each do |template_file|
      if lib_file_names_without_path.include?(template_file)
        print "#{template_file} already exists in the directory.If you want to overwrite it, enter 'y'.Otherwise, press any other key to cancel\n".red
        choice = gets.chomp
        if choice == 'y'
          FileUtils.cp("templates/" + template_file , directory_path + "/lib/")
          puts "File overwritten #{directory_path}/lib/#{template_file}".green
        end
      else
        FileUtils.cp("templates/" + template_file , directory_path + "/lib/")
        puts "File created #{directory_path}/lib/#{template_file}".green
      end
    end
  end

  def self.model(project_number)
    s   = Storage.new
    directory_path = Dir["#{s.project}s/*"].find { |d| d[project_number] }

    puts "Project #{project_number} not found".red if directory_path.nil?
    return if directory_path.nil?

    ARGV.clear

    db_host, database, table_name = get_inputs

    file_name = "#{directory_path}/models/#{table_name}.rb"
    puts "#{file_name} already exists".red if File.exists?(file_name)
    return if File.exist?(file_name)

    model_str = "class #{table_name.camelize} < ActiveRecord::Base\n"\
			"  establish_connection(Storage[host: :#{db_host}, db: :#{database}])\n"\
			"  self.table_name = '#{table_name}'\n"\
			"  self.inheritance_column = :_type_disabled\n"\
			"  self.logger = Logger.new(STDOUT)\n"\
			"end\n"

    File.open(file_name, "w") do |file|
      file.write(model_str)
    end

    puts "File created #{file_name}".green

    # Auto import in keeper.rb if file is there in project_xxxx/lib/keeper.rb
    import_str = "require_relative '../models/#{table_name}'"
    keeper_path = directory_path + "/lib/keeper.rb"

    if File.exist?(keeper_path)
      existing_content = File.read(keeper_path)
      File.open(keeper_path, "w") do |f|
        f.puts import_str
        f.puts existing_content
      end
      puts "Auto imported in #{keeper_path}".green
    end
  end

  def self.get_inputs
    print "Enter DB Host: ".green
    db_host = gets.chomp
    print "Enter DB Name: ".green
    database = gets.chomp
    print "Enter Table Name(snake_case): ".green
    table_name = gets.chomp
    [db_host, database, table_name]
  end
end
