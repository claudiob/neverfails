import re
from django.contrib.contenttypes.models import ContentType
from django.utils.importlib import import_module
from lettuce import *
from lettuce.django import django_url
import urls

# MODELS

@step(u'there are no (.+?)$')
def no_instances(step, objects):
    model_name = objects[:-1] # TODO: improve singularization
    step.given('there is a model called %s' % model_name)
    step.given('there are no instances of that model')

@step(u'(?:|there is )a model called (.+?)$')
def a_model(step, model_name):
    assert ContentType.objects.filter(name=model_name).count() > 0, \
        "No model found called %s" % model_name
    model = ContentType.objects.get(name=model_name).model_class()
    world.last_model = model

@step(u'(?:|there are )no instances of that model$')
def no_instances_of_that_model(step):
    world.last_model.objects.all().delete()

# NAVIGATION

@step(u'I browse the list of (.+?)$')
def browse_the_list_of(step, models):
    step.given('there is a page listing %s' % models)
    step.given('I navigate to that page')

@step(u'there is a page listing (.+?)$')
def an_index_page(step, models):
    step.given('there is a page with URL "%s/"' % models)

@step(u'there is a page with URL "(.+?)"$')
def a_page_with_url(step, url):
    reload(import_module('urls'))    
    assert any(x.regex.match(url) for x in urls.urlpatterns), \
        "No URL pattern found matching %s" % url
    world.last_url = url
    
@step(u'I navigate to that page$')
def navigate_to_that_page(step):
    world.browser.get(django_url(world.last_url))

# CONTENT

@step(u'I should see the text "(.*?)"$')
def should_see_the_text(step, text):
    text = re.sub('\\\\"', '"', text) # Fix double quotes
    assert text in world.browser.page_source, \
        "The text \"%s\" was not found in the current page" % text
