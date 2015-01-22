require 'rubygems'
require 'open3'
require 'rack'
require 'sinatra'
require 'webrick'
require 'webrick/https'
require 'json'
require 'git'
require 'logger'

# Global vars
LOGDIR		= '/etc/puppetlabs/puppet/webhook_logs/' #File.expand_path(File.dirname(__FILE__)) + '/../logs'
SERVER_LOGFILE  = LOGDIR + 'server.log'
SESSION_LOG	= LOGDIR + 'session.log'
MERGE_LOG	= LOGDIR + 'hiera_merge.log'

# Reset some envs
ENV['HOME'] = '/root'
ENV['PATH'] = '/sbin:/usr/sbin:/bin:/usr/bin:/opt/puppet/bin'
# Required to bind on 0.0.0.0 in ruby 1.9* versions of the sinatra gem 
ENV['RACK_ENV']='production'

# Implement an access log for robust logging of user info and access and git output 
LOG = Logger.new(SESSION_LOG)
LOG.info("Setting session log at #{SESSION_LOG}")
LOG.info("Setting server log at #{SERVER_LOGFILE}")

# Certificate Paths:
CERT_PATH = '/etc/puppetlabs/puppet/ssl/coso'

# Server options
opts = {
         :Port               => 6969,
         :Logger             => WEBrick::Log::new(SERVER_LOGFILE, WEBrick::Log::DEBUG),
         :ServerType         => WEBrick::Daemon,
	 :SSLEnable	     => true,
	 :SSLVerifyClient    => OpenSSL::SSL::VERIFY_NONE,
	 :SSLCertificate     => OpenSSL::X509::Certificate.new(File.open("#{CERT_PATH}/star.connectsolutions.com.crt").read),
	 :SSLPrivateKey      => OpenSSL::PKey::RSA.new(File.open("#{CERT_PATH}/star.connectsolutions.com.key").read),
	 :SSLCertName        => [ [ "CN",WEBrick::Utils::getservername ] ]
}

class Server < Sinatra::Base
	# Uncommented get route for easy testing of SSL. `curl https://localhost:8088`
	# Uncomment the raise in prod
	get '/' do
		LOG.info("Attempted access to /")
		raise Sinatra::NotFound
	end

	# https://localhost:8088/deploy_r10k => deploys the branch that had a push event on github.com/connectsolutions/control.git
	post '/deploy_r10k' do
		LOG.info("##### Deploying r10k #####")
		data = request.body
		deploy_r10k(data)	
	end

	# https://localhost:8088/pull_hiera => pulls the hiera data for environment production when a push event occurs on github.com/connectsolutions/puppet-configuration.git
	post '/deploy_hiera' do
		LOG.info("##### Updating hiera #####")
		data = request.body
		pull_hiera(data)
	end

	post '/update_module' do
		data = request.body
		data_hash = JSON.load(data)
		module_name = data_hash['repository']['name'] 
		LOG.info("##### Updating #{module_name} #####")
		if module_name.match(/^puppet-/)
			module_name = module_name.split('puppet-').last
		end
		IO.popen("r10k deploy module #{module_name} -v debug -t 2>&1") do |p|
			LOG.info("r10k started, PID: #{p.pid}")
			p.each {|line| LOG.info(line)}
		end
	end

	#post '/update_hiera_config' do
	#	LOG.info("##### Updating the hiera configuration file #####")
	#	data = request.body 
	#	data_ary = get_data(data)
	#	user = data_ary[0]
	#	sha = data_ary[2]
	#	LOG.info("User #{user} pushed to puppet-hiera-config at #{Time.now}")
	#	LOG.info("SHA for commit: #{sha}")
	#	begin
	#		IO.popen('curl -o /etc/puppetlabs/puppet/hiera.yaml https://raw.githubusercontent.com/connectsolutions/hiera-config/corporate/hiera.yaml?token=AD13QC9HUQf4J7BnFxqjSCPWhxf1fxZ0ks5UuENhwA%3D%3D') {|output|
	#			output.each { |line| LOG.info(line) }
	#		}
	#	rescue Exception => e
	#		LOG.info(e.message)
	#		LOG.info(e.message.backtrace)
	#	end
	#end

	post '/update_webhook' do 
		LOG.info("##### Updating the webhook #####")
		data = request.body 
		data_ary = get_data(data)
		user = data_ary[0]
		sha = data_ary[2]
		LOG.info("User #{user} pushed to r10k_webhook at #{Time.now}")
		LOG.info("SHA for commit: #{sha}")
		begin
			repo = Git.open('/etc/puppetlabs/puppet/r10k_webhook', :log => LOG)
			repo.pull
		rescue Exception => e
			LOG.info(e.message)
			LOG.info(e.message.backtrace)
		end
	end

	post '/update_site' do
		LOG.info("##### Updating the site.pp #####") 
		LOG.info("Current time: #{Time.now}")
		g = Git.open('/etc/puppetlabs/puppet/manifests/', :log => LOG)
		g.pull('origin','production')
	end

	# Not using this yet since the secure_compare method seems to be broken on our version of ruby. 
	#def verify_signature(request)
	#	request.body.rewind
	#	payload_body = request.body.read
	#	signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), ENV['SECRET_TOKEN'], payload_body)
	#   	return halt 500, "Signatures didn't match!" unless Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'])
	#end

	def deploy_r10k(data)
		ub_ary = get_data(data)
		user = ub_ary[0]
		enviro = ub_ary[1]
		sha = ub_ary[2]
		LOG.info("User #{user} deploying to environment #{enviro} on #{Time.now}")
		LOG.info("SHA for commit is #{sha}")
		IO.popen("r10k deploy environment #{enviro} --puppetfile -v debug -t 2>&1") do |p|
               		LOG.info("r10k started, PID: #{p.pid}")
			p.each {|line| LOG.info(line) }
		end
	end

	def get_data(data)
		callback = []
		data_hash = JSON.load(data)
		callback.push(data_hash['pusher'])
		callback.push(data_hash['ref'].split('/').last)
		callback.push(data_hash['after'])
		callback
	end

	def pull_hiera(data)
		ub_ary = get_data(data)
		user = ub_ary[0]
		enviro = ub_ary[1]
		sha = ub_ary[2]
		LOG.info("User #{user} kicked off pulling hiera data on branch #{enviro} at #{Time.now}")
		LOG.info("SHA for commit is #{sha}")
		Merge.new(MERGE_LOG)
	end

	not_found do
		halt 404, 'You shall not pass! (page not found)'
	end
end

Rack::Handler::WEBrick.run(Server, opts) do |server|
	[:INT, :TERM].each { |sig| trap(sig) { server.stop } }
end

