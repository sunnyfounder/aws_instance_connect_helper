# AwsInstanceConnectHelper

AwsInstanceConnectHelper is a Capistrano3 plugin for EC2 Instance Connect deployment bundled with some AWS EC2 rake templates. This is intended as an internal plugin and is therefore not open for contributions, and Sunnyfounder is not responsible for any unintended consequences.

## Setup & Usage

Add this line to your application's Gemfile:

```ruby
group :development do
  gem 'aws_instance_connect_helper', git: 'git@github.com:sunnyfounder/aws_instance_connect_helper.git', tag: 'v0.1.7'
end
```

### Prerequisites

This Gem is intended to be used along with an authorization key saved on your profile (normally located at ~/.aws/credentials)

EC2 Instances on your AWS should be tagged with the according tags:

- Project (Differentiating different projects, eg. core-web, analytics...)
- Environment (eg. production, staging, development...)
- Function (For setting different Capistrano Roles, eg. web, api, shadow...)
- Name (An unique identifier)

### 1. Capistrano3 Plugin

1. Add this line to your application's Capfile

```ruby
require 'aws_instance_connect_helper/capistrano3'
```

2. Configurate the helper (potentially at `lib/capistrano/tasks/aws_helper.rake`)

```ruby
namespace :load do
  task :defaults do
    set :aws_helper_project, 'core-web'
    set :aws_helper_functions, %w[web shadow]
    set :aws_helper_env, proc { fetch :stage }
  end
end
```

3. Invoke `aws_helper:setup` from your config/deploy.rb or config/deploy/ENVIROMENT.rb and easily deploy to servers with Instance Connect.

```ruby
invoke 'aws_helper:setup'
servers = fetch :FUNCTION_servers
```

### 2. SSH Helper

1. Add this line to your application's Rakefile

```ruby
spec = Gem::Specification.find_by_name 'aws_instance_connect_helper'
Dir["#{spec.gem_dir}/lib/tasks/*.rake"].each { |file| load file }
```

2. Access EC2 instances with Instance Connect easily with `rake aws:access`
