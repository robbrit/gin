###
# This is an implementation of the genetic programming problem defined in
# Chapter 4 of A Field Guide to Genetic Programming by Poli, Langdon, and
# McPhee. The problem is to evolve a program that will fit close to the
# function x^2 + x + 1.
###

gin = require "../../gin"
helpers = require "../../helpers"
xjson = require("xjson").xjson

# Genetic programming systems must have closure - that is, for all values that
# you pass to it, it will return a well-defined result. This is not true for
# normal division which will give you an undefined result when you divide by
# zero, so we define a protected divide that will return 0 if the divisor is
# zero.
global.safeDiv = (a, b) ->
  if b == 0
    0
  else
    a / b

g = new gin.Gin(
  # Population size
  popSize: 100

  # The function set to be used - for this problem we just use the four basic
  # arithmetic operations
  functions: [
    ["+", 2],
    ["-", 2],
    ["*", 2],
    ["safeDiv", 2]
  ],
  
  # The terminal set to be used:
  #   x:        the input variable to the function
  #   R(-5, 5): whenever a tree is generated, either in the initial population
  #             or in a mutation operation, R returns a random number. In this
  #             case it will return a random number in [-5, 5).
  terminals: [
    "x",
    "R(-5, 5)"
  ],

  # Input variables
  variables: ["x"],

  # Maximum number of generations the system is going to perform
  maxGenerations: 100

  # Probability of various operations:
  # 90% crossover, 9% reproduce, 1% mutation
  operations:
    crossover: 0.9
    reproduce: 0.09
    mutation: 0.01

  # The fitness function - evaluates the fitness of a given program
  fitness: (tree) ->
    # The fitness will be the absolute error between the function's output and
    # the actual function (x^2 + x + 1) on 0.125 increment steps in the interval
    # -2..2
    x = -2.0
    error = 0

    # in addition, we will add in a parsimony factor to keep trees from getting
    # prohibitively large - large trees slow down the performance of the system
    # dramatically
    numSymbols = helpers.countSymbols tree

    if numSymbols > 30
      # too many symbols? give a fitnessvalue of 1
      1
    else
      # calculate errors for various values of x
      while x <= 2.0
        value = tree(x)
        realValue = x * x + x + 1
        diff = value - realValue
        error += diff * diff
        x += 0.125

      # Finally, truncate the fitness so that it is the range 1..100
      Math.max 1, 100 - Math.sqrt(error) - numSymbols

  # Termination function: accepts a time value, which is the generation we
  # are currently running; and an array of fitness values
  termination: (t, fitness) ->
    # stop if the best fitness is at least 90
    g.currentStats.maxFitness >= 98
)

# Generate the initial population
g.generate()

# Begin executing generation after generation - this will stop when either
# we hit the maximum number of generations, or until the termination function
# is satisfied
g.run()

console.log g._pprint(g.population[g.currentStats.best])
console.log g.currentStats.maxFitness
