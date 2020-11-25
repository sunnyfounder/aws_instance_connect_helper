require 'aws-sdk-ec2'
require 'aws-sdk-ec2instanceconnect'

desc 'Send Public SSH key to EC2 through Instance Connect'
namespace :aws do
  task :access do
    begin
      ec2 = Aws::EC2::Resource.new
      filters = []
      filters.push(name: 'instance-state-name', values: ['running'])

      instances = ec2.instances(filters: filters).map do |instance|
        {
          name: instance.tags.find { |hash| hash[:key] == 'Name' }&.[](:value),
          project: instance.tags.find { |hash| hash[:key] == 'Project' }&.[](:value),
          environment: instance.tags.find { |hash| hash[:key] == 'Environment' }&.[](:value),
          function: instance.tags.find { |hash| hash[:key] == 'Function' }&.[](:value),
          public_ip: instance.public_ip_address,
          availability_zone: instance.placement.availability_zone,
          instance_id: instance.instance_id,
        }
      end

      instances = filter_instances(instances, filter_key: :project)
      instances = filter_instances(instances, filter_key: :environment)
      instance = filter_instances(instances, filter_key: :name).first

      identity = select_prompt :identity, options: ['apps', 'ubuntu']
      public_key = retrieve_public_key

      ec2_connect_client = Aws::EC2InstanceConnect::Client.new
      ec2_connect_client.send_ssh_public_key(
        instance_os_user: identity,
        instance_id: instance[:instance_id],
        availability_zone: instance[:availability_zone],
        ssh_public_key: public_key
      )

      auto_connect = prompt :auto_connect, default: 'y'
      system "ssh #{identity}@#{instance[:public_ip]}" if auto_connect == 'y'
    rescue Aws::EC2::Errors::RequestExpired => e
      sh('aws-mfa')
      retry
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

def filter_instances(instances, filter_key:)
  options = instances.collect{ |instance| instance[filter_key] }.uniq
  selection = select_prompt(filter_key, options: options)
  instances.filter { |instance| instance[filter_key] == selection }
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
  response = STDIN.gets.chomp

  response.strip.empty? ? default : response
end
