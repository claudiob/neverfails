require 'rails/generators'

module Cucumber
  class StepMatch
    def invoke_with_neverfails(multiline_arg)
      begin
        invoke_without_neverfails(multiline_arg)
      rescue Exception => e # NOTE: Test::Unit::AssertionFailedError
        match1 = /No model found called (.+?)\.$/.match(e.message)
        match2 = /No URL pattern found matching \/(.+?)\.$/.match(e.message)
        match3 = /The text "(.+?)" was not found in the current page$/.match(e.message)
        if match1
          create_missing_model match1[1]
        elsif match2
          create_missing_page_listing match2[1]
        elsif match3
          create_missing_text match3[1]
        else
          raise
        end
        return invoke_without_neverfails(multiline_arg) # Try again
      end
    end

    alias_method_chain :invoke, :neverfails

  end
end

def create_missing_model(singular_name)
  # Generate the model and the migration
  Rails::Generators.invoke("model", [singular_name, "--orm=active_record", "--migration"])
  # Run the migration
  ActiveRecord::Migrator.migrate "db/migrate/"
end

def create_missing_page_listing(objects)
  # Generate the controller
  Rails::Generators.invoke("controller", [objects.classify.pluralize, "index"])
  # Add an extra route match "/models" => "model#index"
  @@missing_view_file = "app/views/#{objects}/index.html.erb"
  routes_file = 'config/routes.rb'
  old_routes = File.read(routes_file)
  File.open(routes_file, "w") do |file| 
    file.puts old_routes.gsub(/get "#{objects}\/index"/, 
    "get \"#{objects}/index\"\nmatch \"/#{objects}\" => \"#{objects}#index\"")
  end      
  # Reload routes
  ::Rails.application.reload_routes!
end

def create_missing_text(text)
  File.open(@@missing_view_file, "w") do |file| 
    file.puts "#{text}\n"
  end
  Capybara.current_session.visit $last_url
end
