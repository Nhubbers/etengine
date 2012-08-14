# This mixin is included by the qernel objects that have attributes defined
# in a dataset. See Qernel::Dataset for a general introduction about the
# object. The Dataset object contains a huge hash with all the attributes
# of the area, carriers, converters etc of the graph. Those attributes are
# stored in the database in the dataset_*_data tables. Qernel::Dataset takes
# care of loading them into a single hash.
# Most of the methods defined in this mixin were made to access this hash.
#
# == Example:
#
#     class Qernel::Converter
#       include Qernel::DatasetAttributes
#
#       dataset_accessor :demand
#
#       # above dataset_accessor generates the following methods:
#       def demand
#         dataset_get[:demand]
#       end
#
#       def demand=(val)
#         dataset_set :demand, val
#       end
#     end
#
# So then you can access attributes like:
#
#     c = Qernel::Converter.new
#     c.demand
#     c.dataset_get(:demand)
#
# == Careful:
#
#     c[:demand]
#
# will execute self.send(:demand), and not as you might assume
# dataset_get(:demand).
#
#
# == Overwriting dataset_accessors
#
#     class Qernel::Converter
#       include Qernel::DatasetAttributes
#
#       dataset_accessor :demand
#
#       def demand; "hello world"; end
#     end
#
#     c = Qernel::Converter.new
#     c.dataset_set :demand, 300
#     c.dataset_get(:demand) # => 300
#     # But:
#     c.demand   # => "hello world"
#     c[:demand] # => "hello world"
#

module Qernel::DatasetAttributes

  def self.included(klass)
    klass.send(:attr_accessor, :object_dataset, :observe_set, :observe_get)
    klass.extend(ClassMethods)
  end

  module ClassMethods
    # This creates a bunch of pseudo attr_reader / attr_writer methods
    # that delegate the storage to the Qernel::Dataset#data hash.
    # In most Qernel objects you will see this method called with a list
    # of the attributes stored in the dataset.
    def dataset_accessors(*attributes)
      attributes.flatten.each do |attr_name|
        attr_name_sym = attr_name.to_sym
        #   def attr_name
        #     dataset_get :attr_name
        #   end
        #
        #   def attr_name=(value)
        #     dataset_set :attr_name, value
        #   end
        self.class_eval <<-EOF,__FILE__,__LINE__ +1
          def #{attr_name_sym}
            dataset_get #{attr_name_sym.inspect}
          end

          def #{attr_name_sym}=(value)
            dataset_set #{attr_name_sym.inspect}, value
          end
        EOF
      end
    end

    def dataset_group
      @dataset_group ||= self.name.split("::").last.downcase.to_sym
    end
  end

  # For testing only
    def with(hsh)
      @object_dataset = hsh
      self
    end

  # The dataset belongs to the graph and the Qernel object belongs to the graph:
  # let's get the dataset then. This assumes that the Qernel object has already
  # been assigned a graph and the graph has a dataset too. Don't forget this when
  # you're working with the console.
  def dataset
    graph && graph.dataset
  end

  def dataset_group
    self.class.dataset_group
  end

  def graph
    raise "#{self.class.name} needs to define a 'graph' method, as it includes DatasetAttributes"
  end

  def dataset_key
    @dataset_key ||= id
  end

  def reset_object_dataset
    @object_dataset   = nil
    @observe_set      = nil
    @observe_get      = nil
    @observe_get_keys = []
    @observe_set_keys = []
  end

  # Here we make the object attributes a member of the object itself.
  # The dataset_get/fetch methods act on this variable (which, btw, is
  # made accessible with the attr_accessor at the beginning of this mixin)
  def assign_object_dataset
    if dataset
      @object_dataset   = (dataset.data[dataset_group][dataset_key] ||= {})
      @observe_set      = nil
      @observe_get      = nil
      @observe_get_keys = []
      @observe_set_keys = []
    end
  rescue => e
    raise "Qernel::Dataset: missing dataset item for #{dataset_group.inspect} #{dataset_key}. #{e.inspect}"
  end

  # observe and log changes to an attribute
  def dataset_observe_set(*keys)
    graph[:observe_log] ||= []
    @observe_set_keys   ||= []
    @observe_set_keys    += keys.flatten.map(&:to_sym)
    @observe_set          = true
  end

  # observe access of attributes
  def dataset_observe_get(*keys)
    graph[:observe_log] ||= []
    @observe_get_keys   ||= []
    @observe_get_keys    += keys.flatten.map(&:to_sym)
    @observe_get          = true
  end


  #
  # @example Default usage
  #
  #   def total_costs_of_co2
  #     function(:total_costs_of_co2) do
  #       # ...
  #     end
  #   end
  #
  # @example Runs the calculation only once
  #
  #   def total_costs_of_co2
  #     @counter ||= 0
  #     function(:total_costs_of_co2) do
  #       @counter += 1
  #     end
  #   end
  #   # => 1
  #   # => 1
  #
  # @example Returns nil when exception happens
  #
  #   def total_costs_of_co2
  #     function(:total_costs_of_co2) do
  #       nil * 3.0
  #     end
  #   end
  #   # => nil
  #
  # @example Returns second parameter when exception happens
  #
  #   def total_costs_of_co2
  #     function(:total_costs_of_co2, 0.0) do
  #       nil * 3.0
  #     end
  #   end
  #   # => 0.0
  #
  #
  def function(attr_name, rescue_with = nil)
    # function is memoized, so check if it was called already.
    if object_dataset.has_key?(attr_name)
      # are we in the debugger mode?
      if observe_get
        # log records the access and returns the value
        log :method, attr_name, object_dataset[attr_name]
      else
        # not debugger, so just return the memoized value
        object_dataset[attr_name]
      end
    else
      # function is called for the first time
      if observe_get
        # in debug mode we call #log with a block, which stores the value
        # in the log and returns it back.
        log :method, attr_name do
          begin
            object_dataset[attr_name] = yield
          rescue => e
            # We have an exception, most likely a nil value. log the error
            # with message and apply the value defined in rescue_with param
            log :error, attr_name, e
            object_dataset[attr_name] = rescue_with
          end
        end
      else
        # if not in debug mode, simply yield the value. Do not log the exceptions
        # but simply return the rescue_with value
        object_dataset[attr_name] = yield rescue rescue_with
      end
    end
  end

  def log(type, attr_name, value = nil, &block)
    if block_given?
      graph.logger.log(type, key, attr_name, value, &block)
    else
      graph.logger.log(type, key, attr_name, value)
    end
  end

  # @param attr_name [Symbol]
  def dataset_set(attr_name, value)
    if observe_set # && @observe_set_keys.include?(attr_name)
      log(:set, attr_name, value)
      # str = self.is_a?(Qernel::Converter) ? "#{'-'*200}\n" : ""
      # str += topology_key.to_s.ljust(150) + " #{attr_name}: ".rjust(10)
      # str += value.round(9).inspect.cjust('.', 20, 10)
      # str += "   # by #{@calculation_state} / #{object_dataset[attr_name].inspect}"
      # puts str
    end
    object_dataset[attr_name] = value
  end

  # @param attr_name [Symbol]
  def dataset_get(attr_name)
    if observe_get
      log(:attr, attr_name, object_dataset[attr_name])
    end
    object_dataset[attr_name]

  rescue => e
    raise "#{dataset_key} #{attr_name} not found: #{e.message}"
  end

  def [](attr_name)
    dataset_get(attr_name)
  end

  def []=(attr_name, value)
    dataset_set(attr_name.to_sym, value)
  end
end
