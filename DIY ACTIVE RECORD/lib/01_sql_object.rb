require_relative 'db_connection'
require 'active_support/inflector'
require 'byebug'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    #should return an array with the names of the table's columns
    #We want Cat.columns == [:id, :name, :owner_id]
   return @columns unless @columns == nil  #if truthy, this has already been run and shouldn't go to DB again
   cols = DBConnection.execute2(<<-SQL).first
    SELECT
      *
    FROM
      #{self.table_name}
    SQL
    @columns = cols.map!{ |col| col.to_sym }
  end


  def self.finalize!
    columns.each do |column|
      define_method "#{column}" do
        self.attributes[column.to_sym]
      end
      define_method "#{column}=" do |value|
        self.attributes[column.to_sym] = value
      end
    end
  end


  def self.table_name=(table_name)
    @table_name = table_name
  end


  def self.table_name
    @table_name ||= self.to_s.downcase + "s"
  end


  def self.all
    found = DBConnection.execute(<<-SQL)
      SELECT * FROM #{self.table_name}
    SQL
    self.parse_all(found)
  end


  def self.parse_all(results)
    results.map do |result|
      self.new(result)
    end
  end


  def self.find(id)
    found = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{self.table_name}.id = ?
    SQL
    self.parse_all(found).first
  end


  def initialize(params = {})
    params.each do |attr_name, value|
      name = attr_name.to_sym
      raise "unknown attribute '#{attr_name}'" unless self.class.columns.include?(name)
      self.send("#{name}=", value)
    end
  end


  def attributes
    @attributes ||= {}
  end


  def attribute_values
    self.class.columns.map do |instance|
      self.send(instance)
    end
  end


  def insert
    num_questions = self.class.columns.count
    col_names = self.class.columns.join(", ")
    question_marks = (["?"]*num_questions).join(", ")

    result = DBConnection.execute(<<-SQL, *self.attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end


  def update
    
    result = DBConnection.execute(<<-SQL, *self.attribute_values)
      UPDATE
        table_name
      SET
        col1 = ?, col2 = ?, col3 = ?
      WHERE
        id = ?
    SQL
  end


  def save
    # ...
  end

end
