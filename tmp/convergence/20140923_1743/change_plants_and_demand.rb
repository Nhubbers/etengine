require 'yaml'
 
Dir.glob('producers/*.yml') do |filename|
 
  # load file contents
  producer = YAML.load_file(filename)
 
  # play around with it
  # if producer[:key] =~ /chp/
  #   producer[:marginal_costs] *= 0.5
  # end 

  if producer[:type] == 'MustRunProducer'

    # Only industry CHP should be must-run
    if producer[:load_profile_key] =~ /industry_chp/
      puts 'Found an industy chp... not changing anything'
      # Do nothing
    else
      producer[:type] = 'DispatchableProducer'
    end
  end
 
  if producer[:load_profile_key] =~ /agriculture_chp/
    producer.delete(:load_profile_key)
  end
 
  if producer[:load_profile_key] =~ /buildings_chp/
    producer.delete(:load_profile_key)
  end

  if producer[:load_profile_key] =~ /households_chp/
    producer.delete(:load_profile_key)
  end

  if producer[:load_profile_key] =~ /energy_chp/
    producer.delete(:load_profile_key)
  end

  # write it back to the same file
  File.write(filename, YAML.dump(producer))
 
end

# Change demand (add export from 2013 (35.14 PJ) to the FD + OU + loss)
demand_file = YAML.load_file("archive-info.yml")

if demand_file[:area] == 'nl'
  puts "Changing demand"
  demand_file[:total_demand] = demand_file[:total_demand] + 35.14e9
end

File.write("archive-info.yml", YAML.dump(demand_file))