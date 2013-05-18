Gin is a system for genetic programming using Node.js.

Installation
------------

    npm install gin-gp

Dependencies
------------

All the dependencies should be automatically installed by using:

    npm install

In order to run the examples it helps if you have CoffeeScript installed
globally:

    npm install -g coffee-script

Examples
--------

There are going to be a number of examples in examples/, the current one is
based off of the [Field Guide to Genetic Programming](http://www.gp-field-guide.org.uk/) which is
available for a free PDF download, or in print on Lulu. I'll be adding more
examples from a variety of sources, including [Genetic Programming](http://www.genetic-programming.org/gpbook1toc.html) by
John Koza.

To run an example, simply execute it using `coffee`:

    coffee examples/fggp/ch4.coffee

Testing
-------

To run the tests, simply do:

    npm test

License
-------

Gin is released under the MIT licence.
