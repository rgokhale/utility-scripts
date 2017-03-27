#!/usr/bin/env ruby
require 'date'
require 'time'

# Assumptions
# Timestamps that are not epoch are in UTC


logfile = ARGV[0]
period = 600 # 1 hour
$period_start_epoch = (Time.now.utc.to_i - period.to_i).to_i # UTC time 10 mins ago in epoch

def exit_error(message)
	puts "Critical: #{message}"
	exit 2
end

def exit_warning(message)
	puts "Warning: #{message}"
	exit 1
end

# Check for ERROR or WARNING
def error_check(logline)
	return 'WARNING' if logline.include? 'WARNING'
	return 'ERROR' if logline.include? 'ERROR'
end

def isepoch?(stamp)
	/^\d{10}$/ === stamp
end

def iscustom?(stamp)
	return Time.strptime(stamp, '%b %d %H:%M:%S')
end

def custom_to_epoch(stamp)
	return DateTime.parse(stamp).to_time.to_i # Assume stamp is UTC
end

def isintimeperiod?(stamp_epoch)
	return stamp_epoch.to_i > $period_start_epoch.to_i
end

exit_error('Specify logfile') if ARGV.empty?
exit_error('Cannot find log: ' + logfile) if ! File.file?(logfile)

loglines_in_period = 0
errors_in_period = 0
warnings_in_period = 0

File.open(logfile).each_line do |logline|
	logline_epoch = nil
	logline_parts=logline.split(/\s+/)

	if isepoch?(logline_parts[0])
		logline_epoch = logline_parts[0]
	elsif iscustom?(logline_parts[0..2].join(' '))
		logline_epoch = custom_to_epoch(logline_parts[0..2].join(' '))
	end

	if isintimeperiod?(logline_epoch)
		loglines_in_period += 1
		check = error_check(logline)
		if check == 'ERROR'
			errors_in_period += 1
		elsif check == 'WARNING'
			warnings_in_period += 1
		end
	end
end

exit_warning('No log entries in the last ' + period.to_s + ' secs') if loglines_in_period == 0
exit_error('Found ' + errors_in_period.to_s + ' errors') if errors_in_period > 0
exit_warning('Found ' + warnings_in_period.to_s + ' warning in log') if warnings_in_period > 0

puts 'Ok: Everything looks good'
exit 0