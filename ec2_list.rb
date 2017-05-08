#!/usr/bin/env ruby

require 'aws-sdk'
require 'optparse'

options = {'tag'=>nil}
parser = OptionParser.new do|opts|
  opts.banner = "Usage: ec2_list.rb [options]"
  opts.on('-e', '--tag tag') do |tag|
    options['tag'] = tag;
  end
end
parser.parse!
# Define vars, these can easily be converted into inputs to the script, lets hardcode them for now
region = 'us-west-2'
profile = 'test' # Uses profile in ~/.aws/credentials 
sort_tag = options['tag']
required_attrs = ['instance_id','launch_time','instance_type']

credentials = Aws::SharedCredentials.new(profile_name: profile)
ec2 = Aws::EC2::Client.new(region: region, credentials: credentials)

instance_list = []

ec2.describe_instances.reservations.each do |reservation| 
	reservation.instances.each do |instance|
		instance_attrs = Hash.new
		instance.tags.each do |tag|
			instance_attrs[sort_tag] = tag.value if tag.key == sort_tag
		end
		instance_attrs[sort_tag] = 'unknown' if ! instance_attrs.has_key? sort_tag
		required_attrs.each do |attrs|
			output = 'instance.' + attrs
			instance_attrs[attrs] = eval(output)
		end
		instance_list.push(instance_attrs)
	end
end

sorted_instance_list = instance_list.sort_by { |hsh| hsh[sort_tag] }
sorted_instance_list.each do |instances|
	puts
	instances.each do |key,value| 
		puts key.to_s + ': ' + value.to_s 
	end
end