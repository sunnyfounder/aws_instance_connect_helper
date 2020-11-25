lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "aws_instance_connect_helper/version"

Gem::Specification.new do |spec|
  spec.name          = 'aws_instance_connect_helper'
  spec.version       = AwsInstanceConnectHelper::VERSION
  spec.authors       = ['Michael Fu']
  spec.email         = ['michaelandhsm2@gmail.com']

  spec.summary       = %q{Assists users to manage EC2 Instance Connect oriented services (with Capistrano3 Support)}
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = %w(lib/tasks/aws.rake lib/aws_instanc_connect_helper/capistrano3.rb lib/aws_instanc_connect_helper/ec2_collection.rb)
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "aws-sdk-ec2", "~> 1"
  spec.add_runtime_dependency "aws-sdk-ec2instanceconnect", "~> 1"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", ">= 12.3.3"
  spec.add_development_dependency "byebug", ">= 11.1.3"
end
