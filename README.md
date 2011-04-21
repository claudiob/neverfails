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

Having described behavior in plain text, we create a blank Rails project and make use of [cucumber](https://github.com/gabrielfalcao/lettuce) and [webrat](https://github.com/brynary/webrat) to run the steps.

The following commands set up a new `grocery` Rails project with a basic SQLite database, and a bundle installation with cucumber and webrat:

``` bash
rails new grocery -JT
cd grocery
rm public/index.html
rm public/images/rails.png
echo -e '\ngem "cucumber"' >> Gemfile
echo -e '\ngem "cucumber-rails"' >> Gemfile
echo -e '\ngem "webrat"' >> Gemfile
bundle install
rails g cucumber:install --webrat
echo "require 'cucumber/rails'

if RUBY_VERSION =~ /1.8/
  require 'test/unit/testresult'
  Test::Unit.run = true
end

require 'webrat'
require 'webrat/core/matchers'

Webrat.configure do |config|
  config.mode = :rack
  config.open_error_files = false # Set to true if you want error pages to pop up in the browser
end

World(Webrat::Methods)
World(Webrat::Matchers)

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

To make Rails aware of what the actions in the scenario actually mean, we can either write new step definitions, or import some library that translates common actions into Python commands. One such popular library for Web applications is [webrat](https://github.com/brynary/webrat).

For the sake of the `grocery` example, we define the three steps of the `No apples left` scenario as follows:

* *Given there are no apples*: this step passes if a model called 'Apple' exist and if there are no instances of this model in the database
* *When I browse the list of apples*: this step passes if a page exists listing apples and if I can open that page in a browser
* *Then I should see the text "No apples left"*: this step passes if I see the text "No apples left" in that page

The file `fails_steps.rb` in this package contains these definition in Ruby and webrat code. 

Step 3 (Run and watch it fail)
------------------------------

The following commands copy the content of this file in the project and run the steps again:

``` bash
echo -e "# MODELS

Given /^there are no (\\S+?)$/ do |objects|
  model_name = objects.classify
  Given \"there is a model called #{model_name}\"
  Given \"there are no instances of that model\"
end

Given /^(?:|there is )a model called (.+?)$/ do |model_name|
  assert ActiveRecord::Base.connection.tables.include?(model_name.tableize), 
    \"No model found called #{model_name}\"
  @last_model = model_name.constantize
end

Given /^(?:|there are )no instances of that model$/ do
  @last_model.delete_all
end

# NAVIGATION

When /^I browse the list of (.+?)$/ do |models|
  Given \"there is a page listing #{models}\"
  When \"I navigate to that page\"
end

Given /^there is a page listing (.+?)$/ do |models|
  Given \"there is a page with URL /#{models}\"
end

Given /^there is a page with URL (.+?)$/ do |url|
  assert ActionController::Routing::Routes.routes.collect(&:conditions).
    collect{|route| route[:path_info] =~ url }.any?, 
    \"No URL pattern found matching #{url}\"
  @last_url = url
end

When /^I navigate to that page$/ do 
  visit @last_url
end

# CONTENT

Then /^I should see the text \"([^\"]*)\"$/ do |text|
  begin
    assert_contain text
  rescue Test::Unit::AssertionFailedError => e
    raise e.class, \"The text \\\"#{text}\\\" was not found in the current page\"
  end  
end
" > features/step_definitions/fails_steps.rb
cucumber RAILS_ENV=development
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
rake db:migrate
cucumber RAILS_ENV=development
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
cucumber RAILS_ENV=development
```

The result is now the following, indicating that the *third* step has failed:

```
The text "No apples" left was not found in the current page (Test::Unit::AssertionFailedError)
```

To make the third step pass, we need to add the text "No apples left" to the page that lists apples:

``` bash
echo "No apples left" >| app/views/apples/index.html.erb
cucumber RAILS_ENV=development
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

Neverfails does all of this, so you don't have to (TO COMPLETE)
===============================================================

The `grocery` example shows that Behaviour-Driven Development is time-consuming even for very small applications, with an empty model and a view showing one sentence. 
Time is spent watching the tests fail and writing snippets of code that are common to every web application (creating a model, filling view with text and so on).

Neverfails reduces this time by automatically creating the missing snippets of code when a step fails. 

*** TO COMPLETE ***


How neverfails works (TO COMPLETE)
==================================

*** TO COMPLETE ***


Installing neverfails (TO COMPLETE)
===================================

To follow the example described above, you need [rails](https://github.com/rails/rails) and [bundler](http://gembundler.com) installed on your machine.
The following commands will install these packages, given you already have Ruby installed with [rubygems](http://rubygems.org) enabled:

``` bash
gem install rails
gem install bundler
```

*** TO COMPLETE ***
