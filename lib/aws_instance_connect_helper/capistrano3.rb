require 'aws-sdk-ec2'
require 'aws-sdk-ec2instanceconnect'

namespace :aws_helper do
  task :setup do
    ec2_connect_client = Aws::EC2InstanceConnect::Client.new
    functions = Array(fetch(:aws_helper_functions))

    default_location = "#{Dir.home}/.ssh/id_rsa.pub"
    ask :public_key_location, default_location
    public_key = File.read(fetch(:public_key_location))

    functions.each do |function|
      instances = ec2_instances(function: function)

      server_ips = instances.map(&:public_ip_address)
      set "#{function}_servers".to_sym, server_ips

      instances.each do |instance|
        ec2_connect_client.send_ssh_public_key(
          instance_os_user: 'apps',
          instance_id: instance.instance_id,
          availability_zone: instance.placement.availability_zone,
          ssh_public_key: public_key
        )
      end
    end
  end

  def ec2_instances(function: nil)
    ec2 = Aws::EC2::Resource.new

    filters = []
    filters.push(name: 'instance-state-name', values: ['running'])
    filters.push(name: 'tag:Project', values: [fetch(:aws_helper_project)])
    filters.push(name: 'tag:Environment', values: [fetch(:aws_helper_env)])
    filters.push(name: 'tag:Function', values: [function]) if function

    ec2.instances(filters: filters)
  end
end

namespace :load do
  task :defaults do
    set :aws_helper_env,       (proc { fetch :rails_env })
    set :aws_helper_project,   (proc { abort "Please specify the EC2 instance project name, set :aws_helper_project, 'project name'" })
    set :aws_helper_functions, (proc { abort "Please specify the EC2 instance functions, set :aws_helper_functions, %w[function_1 function_2]" })
  end
end
