gin = require "../../gin"
helpers = require "../../helpers"
xjson = require("xjson").xjson

# most operations are already defined by default in xjson, except for the
# protected divide
xjson ["defun", "%", ["a", "b"],
        ["if", ["=", "b", 0],
               0,
               ["/", "a", "b"]]]

g = new gin.Gin(
  popSize: 10
  functions: [
    ["+", 2],
    ["-", 2],
    ["*", 2],
    ["%", 2]
  ],
  terminals: [
    "x",
    "R(-5, 5)"
  ],
  maxGenerations: 100
  operations:
    crossover: 0.9
    reproduce: 0.09
    mutation: 0.01
  fitness: (tree) ->
    x = -2.0
    error = 0

    # add in a parsimony factor
    numSymbols = helpers.countSymbols tree

    if numSymbols > 30
      1
    else
      while x <= 2.0
        value = xjson ["let", [ ["x", x] ], tree]
        realValue = x * x + x + 1
        diff = value - realValue
        error += diff * diff
        x += 0.1

      Math.max 1, 100 - error - numSymbols

  termination: (t, fitness) ->
    console.log "Step #{t}:"
    console.log "best = #{g.currentStats.maxFitness}"
    console.log "avg = #{g.currentStats.avgFitness}"
    g.currentStats.maxFitness >= 90
)

g.generate()
g.run()

console.log g._pprint(g.population[g.currentStats.best])
