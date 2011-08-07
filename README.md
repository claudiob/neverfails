Behavior-driven development (BDD) consists of [five steps](http://cukes.info/):

1. Describe behavior in plain text
2. Write a step definition
3. Run and watch it fail
4. Write code to make the step pass
5. Run again and see the step pass

Neverfails is a proof of concept to reduce this list to **two steps**:

1. Describe behaviour in plain text
2. Run and watch it pass

With neverfails, step definitions do not simply check whether the existing code satifies the required behaviour or not. They also **write the code** to make them pass.

Neverfails involves an ambitious idea: code generation based on specifications. This idea does not depend on a specific platform or programming language. In principle, it could be implemented with any framework. The current claudiob/neverfails@rails branch uses Rails as a web framework and Ruby as the programming language. The master claudiob/neverfails@master branch, on the other hand, is investigating the same approach using Python and Django.

Behavior-driven development in Rails
====================================

Before approaching neverfails, it is important to understand how Behaviour-Driven Development (BDD) typically takes place within a Rails project.

Step 1 (Describe behavior in plain text)
----------------------------------------

Say we want to create a web store for a *grocery* store, with a distinct page for each product. The *apples* page, for instance, will list the types and quantities of apples currently in store, showing "No apples left" if there are none left in the market. This scenario can be described as:

``` cucumber
Feature: Apples
  Scenario: No apples left
    Given there are no apples
    When I browse the list of apples
    Then I should see the text "No apples left"
```

Having described behavior in plain text, we create a blank Rails project and make use of [cucumber](https://github.com/gabrielfalcao/lettuce) and [capybara](https://github.com/jnicklas/capybara) to run the steps.

The following commands set up a new `grocery` Rails project with a basic SQLite database, and a bundle installation with cucumber and capybara:

``` bash
rails new grocery -JT
cd grocery
rm public/index.html
rm public/images/rails.png
echo -e '\ngem "cucumber"' >> Gemfile
echo -e '\ngem "cucumber-rails"' >> Gemfile
bundle install
rails g cucumber:install
echo "require 'cucumber/rails'
Capybara.default_selector = :css
ActionController::Base.allow_rescue = false" >| features/support/env.rb
sed -i '' -e's/<<: \*test/<<: *development/' config/database.yml
rake db:create
echo -e "Feature: Apples
Scenario: No apples left
    Given there are no apples
    When I browse the list of apples
    Then I should see the text \"No apples left\"
" > features/apples.feature
```

Step 2 (Write step definitions)
-------------------------------

To make Rails aware of what the actions in the scenario actually mean, we can either write new step definitions, or import some library that translates common actions into Python commands. One such popular library for Web applications is [capybara](https://github.com/jnicklas/capybara).

For the sake of the `grocery` example, we define the three steps of the `No apples left` scenario as follows:

* *Given there are no apples*: this step passes if a model called 'Apple' exist and if there are no instances of this model in the database
* *When I browse the list of apples*: this step passes if a page exists listing apples and if I can open that page in a browser
* *Then I should see the text "No apples left"*: this step passes if I see the text "No apples left" in that page

The file `fails_steps.rb` in this package contains these definition in Ruby and capybara code. 

Step 3 (Run and watch it fail)
------------------------------

The following commands copy the content of this file in the project and run the steps again:

``` bash
echo -e "# MODELS

Given /^there are no (\\S+?)\$/ do |objects|
  model_name = objects.classify
  Given \"there is a model called #{model_name}\"
  Given \"there are no instances of that model\"
end

Given /^(?:|there is )a model called (.+?)\$/ do |model_name|
  assert ActiveRecord::Base.connection.tables.include?(model_name.tableize), 
    \"No model found called #{model_name}\"
  @last_model = model_name.constantize
end

Given /^(?:|there are )no instances of that model\$/ do
  @last_model.delete_all
end

# NAVIGATION

When /^I browse the list of (.+?)\$/ do |models|
  Given \"there is a page listing #{models}\"
  When \"I navigate to that page\"
end

Given /^there is a page listing (.+?)\$/ do |models|
  Given \"there is a page with URL /#{models}\"
end

Given /^there is a page with URL (.+?)\$/ do |url|
  assert Rails.application.routes.routes.collect(&:conditions).
    collect{|route| route[:path_info] =~ url }.any?, 
    \"No URL pattern found matching #{url}\"
  \$last_url = url
end

When /^I navigate to that page\$/ do 
  visit \$last_url
end

# CONTENT

Then /^I should see the text \"([^\"]*)\"\$/ do |text|
  begin
    page.should have_content(text)
  rescue Test::Unit::AssertionFailedError => e
    raise e.class, \"The text \\\"#{text}\\\" was not found in the current page\"
  end  
end
" > features/step_definitions/fails_steps.rb
cucumber
```

The result is the following, indicating that the *first* step has failed:

```
No model found called Apple. (Test::Unit::AssertionFailedError)
```

Step 4 (Write code to make the three steps pass)
-------------------------------------------------    
    
To make the first step pass, we need to create an Apple model and store it in the database:

``` bash
rails g model apple             
rake db:migrate RAILS_ENV=test
cucumber
```

The result is now the following, indicating that the *second* step has failed:

```
No URL pattern found matching /apples. (Test::Unit::AssertionFailedError)
```

To make the second step pass, we need to create a URL pattern matching "apples/" that points to a blank HTML page:

``` bash
rails g controller Apples index
sed -i '' '  
/get "apples\/index"/ a\
    match "/apples" => "apples#index"
' config/routes.rb
cucumber
```

The result is now the following, indicating that the *third* step has failed:

```
The text "No apples left" was not found in the current page (RSpec::Expectations::ExpectationNotMetError)
```

To make the third step pass, we need to add the text "No apples left" to the page that lists apples:

``` bash
echo "No apples left" >| app/views/apples/index.html.erb
cucumber
```

Step 5 (Run again and see the step pass)
----------------------------------------

Finally, the three steps pass and running them again returns the message:

``` cucumber
Feature: Apples
  Scenario: No apples left
    Given there are no apples
    When I browse the list of apples
    Then I should see the text "No apples left"
    
1 feature (1 passed)
3 steps (3 passed)
```

Neverfails does all of this, so you don't have to
=================================================

The `grocery` example shows that Behaviour-Driven Development is time-consuming even for very small applications, with an empty model and a view showing one sentence. 
Time is spent watching the tests fail and writing snippets of code that are common to every web application (creating a model, filling view with text and so on).

Neverfails reduces this time by automatically creating the missing snippets of code when a step fails. 


Step 1 (Describe behavior in plain text)
----------------------------------------

Continuing with the grocery example, say we want to add this new scenario:

``` cucumber
Feature: Bananas
  Scenario: No bananas left
    Given there are no bananas
    When I browse the list of bananas
    Then I should see the text "No bananas left"
```

The following commands add the previous scenario to the grocery project and include neverfails to the project:

``` bash
echo -e "Feature: Bananas\n\tScenario: No bananas left\n\t\tGiven there are no bananas\n\t\tWhen I browse the list of bananas\n\t\tThen I should see the text \"No bananas left\"" > features/bananas.feature
echo -e '\ngem "neverfails"' >> Gemfile
bundle install
echo -e "\nrequire 'neverfails'" >> features/support/env.rb
echo -e "\nRails.configuration.cache_classes = false" >> features/support/env.rb
```

Step 2 (Run and watch it pass)
------------------------------

Both the `apples` and the `bananas` scenario can be run with the command:

``` bash
cucumber
```

The `apples` scenario passes since we already wrote all its required. The `bananas` scenario, though, passes as well:

``` cucumber
Feature: Apples
  Scenario: No apples left
    Given there are no apples
    When I browse the list of apples
    Then I should see the text "No apples left"

Feature: Bananas
  Scenario: No bananas left
    Given there are no bananas
Creating tables ...
Creating table bananas_banana
Installing custom SQL ...
Installing indexes ...
    When I browse the list of bananas
    Then I should see the text "No bananas left"
      
2 features (2 passed)
2 scenarios (2 passed)
6 steps (6 passed)
```

How neverfails works
====================

With neverfails, all the steps are parsed by cucumber as normal. However, if a step fails, neverfails *does not* raise an AssertionError but runs the code to make the step pass, then runs the step again. 

So far, neverfails is only able to recognize the three kinds of step included in the `grocery` sample project: creating a model, creating a view, adding text to that view. This is why I call neverfails a proof of concept. If other people find this project interesting (or if I get more time to work on this), then neverfails will grow up to the point where people with no programming experience will be able to create complex web applications by describing what they wish for.


Installing neverfails
=====================

To follow the example described above, you need [rails](https://github.com/rails/rails) and [bundler](http://gembundler.com) installed on your machine.
The following commands will install these packages, given you already have Ruby installed with [rubygems](http://rubygems.org) enabled:

``` bash
gem install rails
gem install bundler
```

The actual neverfails gem can either be downloaded from GitHub or installed by adding the following to the Rails project's Gemfile:

    gem 'neverfails'

and the running:

    bundle install
