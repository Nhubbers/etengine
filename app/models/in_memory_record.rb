# InMemoryRecord adds a few helper methods for models that you want to persist
# in memory, but not necessarly in a database. 
#
# @example
#   class Foo
#      include InMemoryRecord
#
#      def self.load_records
#        # code that loads and returns an array of Foo records
#      end
#   end
#
#   Foo.records     # => {"id_1": <Foo>, "id_2": <Foo>}
#   Foo.all         # => [<Foo>, <Foo>]
#   Foo.get("id_1") # => <Foo>
# 
#
module InMemoryRecord
  extend ActiveSupport::Concern

  def save(*args)
    raise "InMemoryRecord: Object#save not allowed"
  end

  module ClassMethods
    def create(*args)
      raise "InMemoryRecord: Object.create not allowed"
    end

    def all
      # self.name => self.class.name 
      NastyCache.instance.fetch("#{self.name}#all") do
        records.values.uniq
      end
    end

    # records is a hash of key => object
    # there can be multiple keys for one object. 
    # The following keys are removed: nil, ""
    def records
      NastyCache.instance.fetch("#{self.name}#records") do
        load_records.tap do |records| 
          records.delete(nil)
          records.delete("")
        end
      end
    end

    def get(key)
      records[key]
    end

    def add(obj)
      records[obj.key.to_s] = obj
      obj
    end
  end
end
