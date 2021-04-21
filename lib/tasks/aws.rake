require 'aws-sdk-ec2instanceconnect'
require 'aws_instance_connect_helper/ec2_collection'

desc 'Send Public SSH key to EC2 through Instance Connect'
namespace :aws do
  task :access do
    begin
      system 'aws-mfa'
      puts ''

      ec2_client = AwsInstanceConnectHelper::Ec2Collection.new

      filter_instances(ec2_client, filter_key: :project)
      filter_instances(ec2_client, filter_key: :environment)
      filter_instances(ec2_client, filter_key: :name)
      instance = ec2_client.instances.first

      identity = select_prompt :identity, options: ['apps', 'ubuntu']
      public_key = retrieve_public_key

      ec2_connect_client = Aws::EC2InstanceConnect::Client.new
      ec2_connect_client.send_ssh_public_key(
        instance_os_user: identity,
        instance_id: instance[:instance_id],
        availability_zone: instance[:availability_zone],
        ssh_public_key: public_key
      )
      puts "SSH public key sent to #{instance.name}(#{instance.public_ip})"

      auto_connect = prompt :auto_connect, default: 'y'
      system "ssh #{identity}@#{instance[:public_ip]}" if auto_connect == 'y'
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

def filter_instances(ec2_client, filter_key:)
  options = ec2_client.instances.map(&filter_key).uniq
  selection = select_prompt(filter_key, options: options)
  ec2_client.filter(filter_key, selection)
end

def select_prompt(item, options: [], default: 0)
  if options.count == 0
    raise "#{item} options not present"
  elsif options.count == 1
    options[0]
  else
    puts("Select #{item}?")
    options.each_with_index do |val, i|
      puts("  [#{i}] #{val}")
    end
    print('  ')

    response = prompt(item, default: default)
    print("\n")

    options[response.to_i]
  end
end

def prompt(item, default:)
  prompt_string = "Please enter #{item}"
  prompt_string += " (#{default})" if default
  print(prompt_string + ': ')
  response = STDIN.gets
  return default if response.nil?

  response.chomp.strip.empty? ? default : response
end
