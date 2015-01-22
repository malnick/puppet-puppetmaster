require 'rubygems'
require 'git'
require 'logger'
require 'optparse'

#LOG = '/etc/puppetlabs/puppet/webhook_logs/session.log'

class Merge
	
	def initialize(logpath) 
		@log = Logger.new(logpath)
		options = parseopts()
		if options[:debug]
			@log.level = Logger::DEBUG
			debug("Running this thing in debug")		
		else
			@log.level = Logger::INFO
			info("##### Merging puppet configuration and configuration templates at $confdir/data #####")
		end

		if options[:template_override]
			puts "What is the remote templates git repo?\n"
			options[:template_remote] = STDIN.gets.chomp.strip 
		end

		debug(<<-EOT)
		Using options:
		#{options}
		EOT

		debug("Building complete hiera configuration direcotry in #{options[:data_directory]} with templates from #{options[:template_remote]}")	
		
		# Ensure backtrace goes to logs in case of error
		begin
			setup(options)
			merge(options)
		rescue Exception => e
			error("Error: #{e.message}\n
			       Exception: #{e.backtrace.inspect}")
		end
	end

	def parseopts()
		options = {
			:template_remote 	=> 'git@github.com:connectsolutions/puppet-configuration-templates',
			:config_remote		=> 'git@github.com:connectsolutions/puppet-configuration',
			:template_override	=> false,
			:data_directory		=> '/etc/puppetlabs/puppet/data',
			:temp_directory		=> '/tmp/hiera-merge',
			:tmp_temp_dir		=> '/tmp/hiera-merge/templates',
			:tmp_config_dir		=> '/tmp/hiera-merge/config',
			:tmp_data_dir		=> '/tmp/hiera-merge/data',
		}

		OptionParser.new do |opts|
			opts.banner = "Usage: merge.rb $template_remote_url $local_hiera_configuration_repo_path"

			opts.on("-d", "--debug", "Run in debug mode") do |d|
				options[:debug] = true
			end

			opts.on("-t", "--template-remote", "Override default template remote git@github.com:connectsolutions/puppet-configuration-templates") do |t|
				options[:template_override] = t 
			end

		end.parse!
		options
	end

	def setup(options)
		# Ensure the datadir is clean, but do not overwrite it. 
		if Dir.exists?(options[:data_directory])
			info("Data directory already exists: #{options[:data_directory]}")
		else
			info("Data directory not found, creating: #{options[:data_directory]}")
			Dir.mkdir(options[:data_directory])
		end

		# Create the temp directories for git and file operations
		if Dir.exists?(options[:temp_directory])
			info("Clearing old temporary direcotry at #{options[:temp_directory]}")
			FileUtils.remove_dir(options[:temp_directory], force = true)
		end

		# Create baseline tmp directory structure
		info("Creating new temporary directory at #{options[:temp_directory]}")
		Dir.mkdir(options[:temp_directory])
		info("Creating new temporary data directory at #{options[:tmp_data_dir]}")
		Dir.mkdir(options[:tmp_data_dir])

		# Clone the repos
		info("Cloning #{options[:template_remote]} to #{options[:tmp_temp_dir]}")
		templates 	= Git.clone(options[:template_remote], options[:tmp_temp_dir])
		info("Cloning #{options[:config_remote]} to #{options[:tmp_config_dir]}")
		config		= Git.clone(options[:config_remote], options[:tmp_config_dir])
	end

	def merge(options)
		# Cp contents of tmp_temp_dir and tmp_config_dir to tmp_data_dir
		info("Copying #{options[:tmp_temp_dir]}/. to #{options[:tmp_data_dir]}")
		FileUtils.cp_r(options[:tmp_temp_dir] + '/.', options[:tmp_data_dir])

		# Cp contents of tmp_config_dir to tmp_data_dir
		info("Copying #{options[:tmp_config_dir]}/. to #{options[:tmp_data_dir]}")
		FileUtils.cp_r(options[:tmp_config_dir] + '/.', options[:tmp_data_dir])
		
		# Mv temp data directory to the puppet configuration $PATH
		info("Moving temporary data directory into the Puppet $datadir $PATH: #{options[:tmp_data_dir]} => #{options[:data_directory]}")
		
		# Backup existing data directory
		if Dir.exists?(options[:data_directory])
			info("Backing up old data directory: #{options[:data_directory]}.bak")
			if Dir.exists?("#{options[:data_directory]}.bak")
				FileUtils.rm_rf("#{options[:data_directory]}.bak")
			end
			File.rename(options[:data_directory], "#{options[:data_directory]}.bak")
			info("Removing old data directory")
			FileUtils.rm_rf(options[:data_directory])
		end

		# Make the move
		File.rename(options[:tmp_data_dir], options[:data_directory])
		info("Done.")
	end	

	def info(message)
		@log.info(message)
	end

	def debug(message)
		@log.debug(message)
	end

	def error(message)
		abort("#{@log.error(message)}")
	end

end
#Merge.new('/tmp/hiera-merge.log')

