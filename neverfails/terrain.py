from lettuce import before, after, world
from selenium import webdriver

@before.all
def set_browser():
    world.browser = webdriver.Firefox()

@after.all
def shutdown_browser(results):
    world.browser.quit()
