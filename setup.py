from distutils.core import setup

setup(
    name = "neverfails",
    packages = ["neverfails"],
    version = "0.0.1",
    requires = ['lettuce', 'selenium', 'django'],
    install_requires = ['lettuce', 'selenium', 'django'],
    description = "Code generation based on specifications.",
    author = "Claudio B.",
    author_email = "github.com/claudiob",
    url = "https://github.com/claudiob/neverfails/",
    download_url = "https://github.com/ff0000/neverfails",
    keywords = ["django", "admin", "bdd", "tdd", "documentation", "lettuce"],
    classifiers = [
        "Programming Language :: Python",
        "Development Status :: 3 - Alpha",
        "Framework :: Django",
        "Natural Language :: English",
        "Environment :: Web Environment",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
        "Topic :: Software Development :: Documentation",
        "Topic :: Software Development :: Testing",
        "Topic :: Utilities"
        ],
    long_description = """\
Code generation based on specifications.
----------------------------------------

Neverfails involves an ambitious idea: code generation based on specifications. 
This idea does not depend on a specific platform or programming language. 
In principle, it could be implemented with any framework. 
Actually, I have decided to test it using Django as a web framework and 
Python as the programming language. 

Similarly to lettuce, neverfails recognizes the steps using regular expressions 
and checks whether they pass or fail. If the step fails, neverfails does not
raise an AssertionError but runs the code to make the step pass, then runs the 
step again. 
"""
)

# To create the package: python setup.py register sdist upload