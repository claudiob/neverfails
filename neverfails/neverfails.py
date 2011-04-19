import re
from os import mkdir
from time import sleep
from django.core.exceptions import ObjectDoesNotExist
from django.contrib.contenttypes.models import ContentType
from django.core.management import call_command
from django.conf import settings
from django.db.models import loading
from lettuce import *
from lettuce.django import django_url
from lettuce.core import Step
import fails

def new_run(step, ignore_case = True):
    try:
        return step.old_run(ignore_case)
    except AssertionError:
        match1 = re.match('No model found called (.+?)$', step.why.cause)
        match2 = re.match('No URL pattern found matching (.+?)/$', step.why.cause)
        match3 = re.match('The text (.+?) was not found in the current page$', step.why.cause)
        if match1:
            create_missing_model(match1.groups()[0])
        elif match2:
            create_missing_page_listing(match2.groups()[0])
        elif match3:
            create_missing_text(match3.groups()[0], world.browser.current_url)
        else:
            raise
        step.failed = False
        return step.old_run(ignore_case)
Step.old_run = Step.run
Step.run = new_run


def pluralize(word):   return word + 's'        # Best so far
def modelize(word):    return word.capitalize() # Best so far

def create_missing_model(singular_name):
    plural_name = pluralize(singular_name) # user >> walnuts
    model_name = modelize(singular_name) # user >> User
    # create the app
    call_command('startapp', plural_name)
    # create the model
    with open('%s/models.py' % plural_name,'a') as f:
        f.write("class %s(models.Model):\n" % model_name)
        f.write("    pass")
    # create the templates folder
    mkdir('%s/templates' % plural_name)
    # add to INSTALLED_APPS
    with open('settings.py','a') as f:
        f.write("INSTALLED_APPS += ('%s', )\n" % plural_name)
    # also add to INSTALLED_APPS in memory
    apps = getattr(settings, "INSTALLED_APPS")
    apps.append(plural_name)
    setattr(settings, "INSTALLED_APPS", apps)
    # load the model
    loading.cache.loaded = False
    call_command('syncdb', interactive=False)
    
def create_missing_page_listing(objects):
    # So far, just one static list file with TemplateView
    world.last_template = '%s/templates/%s.html' % (objects, objects)
    with open(world.last_template,'w') as f:
        f.write("<!-- Incepted -->\n")
    # add to urls.py
    with open('urls.py','a') as f:
        f.write("from django.views.generic import TemplateView\n")
        f.write("urlpatterns += patterns('',(r'^%s/',  TemplateView.as_view(template_name='%s.html')),)\n" % (objects, objects))
    sleep(1.5) # autoreload spawn every 1 second
    
def create_missing_text(text, url):
    # TODO: reverse URL to understand which template to edit
    # For now, just one static list file
    with open(world.last_template,'a') as f:
        f.write(text + '\n')
    # also add to the current page
    world.browser.get(django_url(world.last_url))
    sleep(1.5) # autoreload spawn every 1 second
