module Gql::QueryInterface::Base

  def input_value
    @input_value
  end

  def input_value=(val)
    @input_value = val
  end

  def scope
    self
  end

  # Figures out the kind of query and executes it
  #
  # @param [String, Gquery] query Escaped query_string
  # @param [String] input_value user value from param
  # @return [Float]
  # @raise [Gql::GqlError] if query is not valid.
  #
  def query(obj, input_value = nil)
    self.input_value = input_value.to_s
    if obj.is_a?(Gquery)
      execute_gquery_key(obj.key)
    elsif obj.is_a?(Input)
      self.input_value = "#{self.input_value}#{obj.v1_legacy_unit}" unless self.input_value.include?('%')
      execute_input(Gql::QueryInterface::Preparser.new(obj.query).parsed)
    elsif parsed = Gql::QueryInterface::Preparser.new(obj).parsed
      # pure GQL string
      execute_parsed_query(parsed)
    else
      raise Gql::GqlError.new("Gql::QueryInterface.query query is not valid: #{clean(obj)}.")
    end
  ensure
    self.input_value = nil
  end

  # @return [Array<String>] Debug messages
  #
  def debug(query_string)
    if parsed = Gql::QueryInterface::Preparser.new(query_string).parsed
      msg = []
      parsed.debug(scope, msg)
      msg
    else
      raise Gql::GqlError.new("Gql::QueryInterface.query query is not valid: #{clean(query_string)}.")
    end
  rescue => e
    e.inspect # return the error message as a string
  end

  # Is the given gquery_string valid?
  #
  def check(query)
    Gql::QueryInterface::Preparser.new(query).valid?
  end

  # A subquery is a call to another query.
  # e.g. "SUM(QUERY(foo))"
  #
  def subquery(gquery_key)
    if gquery = get_gquery(gquery_key)
      execute_parsed_query(gquery.parsed_query)
    else
      nil
    end
  end
  alias execute_gquery_key subquery


protected

  def execute_input(parsed_query)
    parsed_query.result(scope)
  rescue => e
    raise Gql::GqlError.new("UPDATE: #{parsed_query.text_value}:\n #{e.inspect}")
  end

  def execute_parsed_query(parsed_query)
    # DEBT: decouple from Current.gql
    #       maybe add a Observer to graph:
    #       in gql: present_graph.observe_calculate(Current.gql)
    #       here:   present_graph.notify_observers!
    #
    Current.gql.prepare if !Current.gql.calculated?
    
    parsed_query.result(scope)
  rescue => e
    raise Gql::GqlError.new("Query: #{parsed_query.text_value}.\n #{e.inspect}")
  end

  def get_gquery(gquery_or_key)
    if gquery_or_key.is_a?(::Gquery)
      gquery_or_key
    else
      ::Gquery.get(gquery_or_key)
    end
  end

  def clean(query_string)
    Gql::QueryInterface::Preparser.new(query_string).clean
  end
end
