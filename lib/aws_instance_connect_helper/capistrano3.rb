require 'aws-sdk-ec2instanceconnect'
require 'aws_instance_connect_helper/ec2_collection'

namespace :aws_helper do
  task :setup do
    begin
      system 'aws-mfa'
      puts ''

      ec2_client = AwsInstanceConnectHelper::Ec2Collection.new

      functions = Array(fetch(:aws_helper_functions))
      functions.each do |function|
        instances = ec2_client.instances(project: fetch(:aws_helper_project), environment: fetch(:aws_helper_env).to_s, function: function)
        server_ips = instances.map(&:public_ip)
        set "#{function}_servers".to_sym, server_ips
      end


      ec2_connect_client = Aws::EC2InstanceConnect::Client.new
      public_key = retrieve_public_key

      ec2_client.instances(function: functions).each do |instance|
        ec2_connect_client.send_ssh_public_key(
          instance_os_user: 'apps',
          instance_id: instance[:instance_id],
          availability_zone: instance[:availability_zone],
          ssh_public_key: public_key
        )
      end
    rescue StandardError => e
      puts e.inspect
      raise
    end
  end
end

def retrieve_public_key
  default_location = "#{Dir.home}/.ssh/id_rsa.pub"
  location = prompt :public_key_location, default: default_location
  File.read(location)
end

def prompt(item, default:)
  prompt_string = "Please enter #{item}"
  prompt_string += " (#{default})" if default
  print(prompt_string + ': ')
  response = STDIN.gets.chomp

  response.strip.empty? ? default : response
end

namespace :load do
  task :defaults do
    set :aws_helper_env,       (proc { fetch :rails_env })
    set :aws_helper_project,   (proc { abort "Please specify the EC2 instance project name, set :aws_helper_project, 'project name'" })
    set :aws_helper_functions, (proc { abort "Please specify the EC2 instance functions, set :aws_helper_functions, %w[function_1 function_2]" })
  end
end
