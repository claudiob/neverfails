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

Neverfails involves an ambitious idea: code generation based on specifications. 
This idea does not depend on a specific platform or programming language. 
In principle, it could be implemented with any framework. 
In this [master branch](https://github.com/claudiob/neverfails/tree/master), I test this idea using Django as a web framework and Python as the programming language.
In the [rails branch](https://github.com/claudiob/neverfails/tree/rails), I use instead Ruby on Rails.
[cowboycoded](https://github.com/cowboycoded/never_fails) is also investigating this approach using Ruby and Rails.

Behavior-driven development in Django
=====================================

Before approaching neverfails, it is important to understand how Behaviour-Driven Development (BDD) typically takes place within a Django project.

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

Having described behavior in plain text, we create a blank Django project and make use of [lettuce](https://github.com/gabrielfalcao/lettuce) to run the steps. Lettuce is a BDD tool for python, 100% inspired on [cucumber](https://github.com/aslakhellesoy/cucumber). 

The following commands set up a new `grocery` Django project with a basic SQLite database, and a virtual environment with lettuce:

``` bash
django-admin.py startproject grocery
cd grocery
echo -e "\nDATABASES = {'default': {'ENGINE': 'django.db.backends.sqlite3', 'NAME': 'grocery.db',}}" >> settings.py 
virtualenv env
source env/bin/activate
pip install lettuce
echo -e "\nINSTALLED_APPS += ('lettuce.django', )" >> settings.py
python manage.py syncdb --noinput
mkdir features
echo -e "Feature: Apples\n\tScenario: No apples left\n\t\tGiven there are no apples\n\t\tWhen I browse the list of apples\n\t\tThen I should see the text \"No apples left\"" > features/apples.feature
```
The following commands run the project in a local server instance. They should be executed in a separate shell, since the basic Django server cannot be daemonized:

``` bash
cd grocery
source env/bin/activate
python manage.py runserver
```
    
Step 2 (Write step definitions)
-------------------------------

To make Django aware of what the actions in the scenario actually mean, we can either write new step definitions, or import some library that translates common actions into Python commands. One such popular library for Web applications is [webrat](https://github.com/brynary/webrat), but is only available for Ruby. A very limited Python-equivalent is [radish](https://github.com/ff0000/radish).

For the sake of the `grocery` example, we define the three steps of the `No apples left` scenario as follows:

* *Given there are no apples*: this step passes if a model called 'Apple' exist and if there are no instances of this model in the database
* *When I browse the list of apples*: this step passes if a page exists listing apples and if I can open that page in a browser
* *Then I should see the text "No apples left"*: this step passes if I see the text "No apples left" in that page

The file `fails.py` in this package contains these definition in Python and lettuce code. 

Step 3 (Run and watch it fail)
------------------------------

The following commands include this file in the project and run the steps again:

``` bash
pip install neverfails
echo -e "from neverfails.terrain import *\nfrom neverfails import fails" > terrain.py
python manage.py harvest -S features/
```

The result is the following, indicating that the *first* step has failed:

```
AssertionError: No model found called apple
```

Step 4 (Write code to make the three steps pass)
-------------------------------------------------    
    
To make the first step pass, we need to create an application called apples, add it to the list of installed apps, create an Apple model and store it in the database:

``` bash
python manage.py startapp apples
echo -e "INSTALLED_APPS += ('apples', )" >> settings.py 
echo -e "class Apple(models.Model):\n\tpass" >> apples/models.py
python manage.py syncdb --noinput
python manage.py harvest -S features/
```

The result is now the following, indicating that the *second* step has failed:

```
AssertionError: No URL pattern found matching apples/
```

To make the second step pass, we need to create a URL pattern matching "apples/" that points to a blank HTML page:

``` bash
echo -e "from django.views.generic import TemplateView\nurlpatterns += patterns('',\n\t(r'^apples/',  TemplateView.as_view(template_name='apples.html')),\n)\n" >> urls.py
mkdir apples/templates
touch apples/templates/apples.html
python manage.py harvest -S features/
```

The result is now the following, indicating that the *third* step has failed:

```
AssertionError: The text "No apples" left was not found in the current page
```

To make the third step pass, we need to add the text "No apples left" to the page that lists apples:

``` bash
echo -e "No apples left" >> apples/templates/apples.html
python manage.py harvest -S features/
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
1 scenario (1 passed)
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

The following commands add the previous scenario to the grocery project and include neverfails step definitions:

``` bash
echo -e "Feature: Bananas\n\tScenario: No bananas left\n\t\tGiven there are no bananas\n\t\tWhen I browse the list of bananas\n\t\tThen I should see the text \"No bananas left\"" > features/bananas.feature
echo -e "from neverfails.terrain import *\nfrom neverfails import neverfails" >| terrain.py
```

Step 2 (Run and watch it pass)
------------------------------

Both the `apples` and the `bananas` scenario can be run with the command:

``` bash
python manage.py harvest -S features/
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

Similarly to lettuce, neverfails recognizes the steps using regular expressions and checks whether they pass or fail. If the step fails, neverfails *does not* raise an AssertionError but runs the code to make the step pass, then runs the step again. 

So far, neverfails is only able to recognize the three kinds of step included in the `grocery` sample project: creating a model, creating a view, adding text to that view. This is why I call neverfails a proof of concept. If other people find this project interesting (or if I get more time to work on this), then neverfails will grow up to the point where people with no programming experience will be able to create complex web applications by describing what they wish for.

Installing neverfails
=====================

To follow the example described above, you need [pip](http://pypi.python.org/pypi/pip), [virtualenv](http://www.virtualenv.org) and [django](http://www.djangoproject.com/) installed on your machine.
The following commands will install these three packages, given you already have Python installed with [setuptools](http://pypi.python.org/pypi/setuptools) enabled:

``` bash
easy_install pip
pip install django
pip install virtualenv
```
    
The actual neverfails package can either be [downloaded from GitHub](https://github.com/claudiob/neverfails) or [installed from PyPi](http://pypi.python.org/pypi/neverfails) by running:

``` bash
pip install neverfails
```
