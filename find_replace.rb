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

  def replace()
    @replace
  end

  # Count occurances find text occurs in configured fields
  #
  # @param
  # @return [Array<Hash>] array of table, fields, count hashes
  def find_counts()
    # Search through given fields for given text
    counts = Array.new
    find_text = @replace['replace']['find']
    @replace['replace']['tables'].each do |table, fields|
      query = find_query(find_text, table, fields.clone)
      @dbconn.query(query).each do |row|
        count_hash = {table: table, fields: fields, count: row['total']}
        counts.push count_hash
      end
    end
    counts
  end

  # Replace text in database fields
  #
  # @param
  # @return
  def replace_text()
    @replace['replace']['tables'].each do |table, fields|
      fields.each do |field|
        #begin
          query = update_query(@replace['replace']['find'], @replace['replace']['replace'], table, field)
          puts query
          @dbconn.query(query)
        #rescue
        #  return false
        #end
      end
    end
    return true
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

  # Generates query to replace test
  #
  # @param find_text [String]
  # @param replace_text [String]
  # @param table [String]
  # @param field [String]
  # @return [String] update query
  def update_query(find_text, replace_text, table, field)
    return "UPDATE #{table} SET #{field} = REPLACE(#{field}, '#{find_text}', '#{replace_text}')"
  end

end

select_option = ''

while select_option != 'x'
  puts "\n\n"
  puts "*******"
  puts "Options"
  puts "*******"
  puts "(0) Exit script"
  puts "(1) Show Find/Replace text"
  puts "(2) Find Occuranaces"
  puts "(3) Replace Text"

  select_option = ask("Select Option : ", Integer){|q| q.in = 0..10}

  find_replace = FindReplace.new

  case select_option
  when 1
    puts "\n\n"
    puts "Find : #{find_replace.replace['replace']['find']}"
    puts "Replace : #{find_replace.replace['replace']['replace']}"
  when 2
    puts "\n\n"
    puts "Table | Fields | Count"
    counts = find_replace.find_counts
    counts.each do |count|
      puts "#{count[:table]} | #{count[:fields]} | #{count[:count]}"
    end
  when 3
    puts "\n\n"
    if find_replace.replace_text
      puts "String replaced!"
    else
      puts "Error occured."
    end
  when 0
    exit(0)
  else
    puts "Invalid Option"
  end

end
