#!/bin/bash
# This script shows what the latest version neverfails is able to do.
# NOTE: For the sake of speed, this script assumes all the required gems
# are already installed in the system, so 'bundle install --local' is used.

# The script creates a Rails application called 'grocery', adds a feature
# called banana and runs neverfails to creates the Rails code that generates
# the Banana model, controller, index view with a given text and sets the
# route to this view

rails new grocery -JT
cd grocery
rm public/index.html
rm public/images/rails.png
echo -e '\ngem "cucumber"' >> Gemfile
echo -e '\ngem "cucumber-rails"' >> Gemfile
echo -e '\ngem "neverfails"' >> Gemfile
bundle install --local
rails g cucumber:install
echo "require 'cucumber/rails'
require 'neverfails'
Rails.configuration.cache_classes = false
Capybara.default_selector = :css
ActionController::Base.allow_rescue = false" >| features/support/env.rb
sed -i '' -e's/<<: \*test/<<: *development/' config/database.yml
rake db:create
cp ../fails_steps.rb features/step_definitions/
echo "Feature: Bananas
	Scenario: No bananas left
		Given there are no bananas
		When I browse the list of bananas
		Then I should see the text \"No bananas left\"" > features/bananas.feature
cucumber