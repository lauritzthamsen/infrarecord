class ActiveRecord::Base
  attr_accessible :body, :title

  def self.show_sql(query_string)
    self.transaction do
      str = StringIO.new
      self.logger = Logger.new(str)
      eval query_string
      self.logger = ActiveRecord::Base.logger

      puts str.string
      # perform some regex on str to get the actual query

      raise ActiveRecord::Rollback, "Rollback Query because done only for SQL"
    end
  end
end


puts "Environment set up"
