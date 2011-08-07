# MODELS
  
Given /^there are no (\S+?)$/ do |objects|
  model_name = objects.classify
  Given "there is a model called #{model_name}"
  Given "there are no instances of that model"
end

Given /^(?:|there is )a model called (.+?)$/ do |model_name|
  assert ActiveRecord::Base.connection.tables.include?(model_name.tableize), 
    "No model found called #{model_name}"
  @last_model = model_name.constantize
end

Given /^(?:|there are )no instances of that model$/ do
  @last_model.delete_all
end

# NAVIGATION

When /^I browse the list of (.+?)$/ do |models|
  Given "there is a page listing #{models}"
  When "I navigate to that page"
end

Given /^there is a page listing (.+?)$/ do |models|
  Given "there is a page with URL /#{models}"
end

Given /^there is a page with URL (.+?)$/ do |url|
  assert Rails.application.routes.routes.collect(&:conditions).
    collect{|route| route[:path_info] =~ url }.any?, 
    "No URL pattern found matching #{url}"
  $last_url = url
end

When /^I navigate to that page$/ do 
  visit $last_url
end

# CONTENT

Then /^I should see the text "([^"]*)"$/ do |text|
  begin
    page.should have_content(text)
  rescue Test::Unit::AssertionFailedError => e
    raise e.class, "The text \"#{text}\" was not found in the current page"
  end  
end