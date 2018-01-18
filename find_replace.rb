require 'mysql2'
require 'highline/import'
require 'yaml'

class FindReplace
  def initialize()
    # Replace with cases for missing file and optional file location.
    @dbconfig = YAML.load_file("./dbconfig.yml")
    @replace = YAML.load_file("./replace.yml")
    db = @dbconfig['ulib']
    @dbconn = Mysql2::Client.new(:host => @dbconfig['ulib']['host'], :username => @dbconfig['ulib']['user'], :password => @dbconfig['ulib']['password'], :database => @dbconfig['ulib']['name'])
  end

  # Count occurances find text occurs in configured fields
  #
  # @param
  # @return [String]
  def find_count()
    # Search through given fields for given text
    find_text = @replace['replace']['find']
    puts "Find text: #{find_text}"
    @replace['replace']['tables'].each do |table, fields|
      query = find_query(find_text, table, fields)
      puts query
      @dbconn.query(query).each do |row|
        puts row['total']
      end
    end
  end

  # Generates query that searches fields for text
  #
  # @param find_text [String] text to find
  # @param table [String] table to search in
  # @param fields [Array<String>] fields to search in
  # @return [String] search query
  def find_query(find_text, table, fields)
    where_clause = "#{fields.shift} LIKE '%#{find_text}%' "
    fields.each do |field|
      where_clause += "OR #{field} LIKE '%#{find_text}%' "
    end
    return "SELECT COUNT(*) total FROM #{table} WHERE #{where_clause}"
  end


end

select_option = ''

while select_option != 'x'
  puts "\n\n"
  puts "*******"
  puts "Options"
  puts "*******"
  puts "(0) Exit script"
  puts "(1) Count Find Occuranaces"

  select_option = ask("Select Option : ", Integer){|q| q.in = 0..10}

  find_replace = FindReplace.new

  case select_option
  when 1
    puts "\n\n"
    puts "1. Selected"
    find_replace.find_count
  when 0
    exit(0)
  else
    puts "Invalid Option"
  end

end
