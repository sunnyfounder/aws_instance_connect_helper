require 'aws-sdk-ec2'

module AwsInstanceConnectHelper
  class Ec2Collection
    def initialize
      ec2 = Aws::EC2::Resource.new
      @_instances = ec2.instances.map do |instance|
        OpenStruct.new(
          name: instance.tags.find { |hash| hash[:key] == 'Name' }&.[](:value),
          project: instance.tags.find { |hash| hash[:key] == 'Project' }&.[](:value),
          environment: instance.tags.find { |hash| hash[:key] == 'Environment' }&.[](:value),
          function: instance.tags.find { |hash| hash[:key] == 'Function' }&.[](:value),
          state: instance.state.name,
          public_ip: instance.public_ip_address,
          availability_zone: instance.placement.availability_zone,
          instance_id: instance.instance_id,
        )
      end
    end

    def filter(key, value)
      @_instances = select_instances(_instances, key: key, selection: value)
    end

    def instances(state: 'running', **kwargs)
      kwargs[:state] = state
      filtered_instances = _instances.dup

      kwargs.each do |key, value|
        filtered_instances = select_instances(filtered_instances, key: key, selection: value)
      end

      filtered_instances
    end

    private

    attr_reader :_instances

    def select_instances(instances, key:, selection:)
      instances.filter do |instance|
        Array(selection).include?(instance[key])
      end
    end
  end
end
