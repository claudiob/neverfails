#!/bin/bash
# This script shows what the latest version neverfails is able to do.
# For the sake of speed, if all the required gems are already installed in the 
# system, invoke with --local, so 'bundle install --local' is used.

# The script creates a Rails application called 'grocery', adds a feature
# called banana and runs neverfails to creates the Rails code that generates
# the Banana model, controller, index view with a given text and sets the
# route to this view

rm -rf grocery
rails new grocery -JT
cd grocery
echo "gem 'cucumber'
gem 'cucumber-rails'
gem 'neverfails'" >> Gemfile
if [ "$1" = "--local" ]
then 
  bundle install --local
else
  bundle install
fi
rails g cucumber:install
echo "require 'cucumber/rails'
require 'neverfails'
require 'neverfails/fails_steps'
Rails.configuration.cache_classes = false" >| features/support/env.rb
sed -i '' -e's/<<: \*test/<<: *development/' config/database.yml
rake db:create
echo "Feature: Bananas
	Scenario: No bananas left
		Given there are no bananas
		When I browse the list of bananas
		Then I should see the text \"No bananas left\"" > features/bananas.feature
cucumber