xjson = require "xjson"
ls = require "lispyscript"
_ = require "underscore"
randgen = require "randgen"
clone = require "clone"

class Gin
  ###
  # Sets up the GP environment
  # Args:
  # - functions: array of function names. array elements should be pairs:
  #              (name of function, arity of function)
  # - terminals: array of terminals
  # - variables: array of input variables
  # - fitness: function that accepts a tree and returns a number
  # - popSize: (default: 100) size of the population
  # - maxInitialDepth: (default: 5) maximum initial depth of the trees
  # - maxGenerations: (default: 500) maximum number of generations to run
  # - operations:
  #   - crossover: (default: 0.75) probability of crossover
  #   - reproduce: (default: 0.15) probability of reproduction
  #   - mutation: (default: 0.1) probability of mutation
  #   - terminalChance: (default: 0.1) chance of choosing a terminal on
  #                     crossover/mutation
  #   - mutationDepth: (default: 1) lambda for poisson distribution regarding
  #                    mutation depth
  # - termination: function that accepts an integer and an array of numbers
  #                that returns true if the system should stop execution
  ###
  constructor: (options={}) ->
    @options = _.defaults options,
      popSize: 100
      maxInitialDepth: 5
      maxGenerations: 500
      operations: _.defaults(options.operations or {},
        crossover: 0.75
        reproduce: 0.15
        mutation: 0.1
        terminalChance: 0.1
        mutationDepth: 1
      )

    @stats = []

  generate: =>
    # generate the initial population using ramped half-and-half
    sectionSize = @options.popSize / @options.maxInitialDepth

    @population =
      for i in [1..@options.popSize]
        depth = Math.max 1, Math.floor(i / sectionSize)
        @_generateOne depth

    @_calculateFitness()
    return

  _generateOne: (depth) =>
    if depth == 0
      # randomly select one from the terminals
      @_transformTerminal(randgen.rlist @options.terminals)
    else
      [func, arity] = randgen.rlist @options.functions
      args = (@_generateOne(depth - 1) for i in [1..arity])

      [func].concat args

  step: =>
    # breed the next generation
    @_breed()
    
    # get the fitness of everyone
    @_calculateFitness()

  run: =>
    i = 0
    while i < @options.maxGenerations
      i++
      @step()
      if @options.termination i, @fitness
        break

  # get the next generation
  _breed: =>
    nextGeneration = []
    while nextGeneration.length < @options.popSize
      # choose an operation
      op = @_getOp()

      if op == "crossover"
        [parent1, parent2] = @_selectNext 2

        [child1, child2] = @_crossover(parent1, parent2)

        nextGeneration.push child1
        nextGeneration.push child2
      else if op == "reproduce"
        nextGeneration.push @_selectNext()[0]
      else
        nextGeneration.push @_mutate(@_selectNext()[0])

    @population = nextGeneration

    return

  _chooseTerminal: =>
    randgen.rbernoulli(@options.operations.terminalChance) == 1

  # gets an operation
  _getOp: =>
    r = randgen.runif()

    if r < @options.operations.crossover
      "crossover"
    else if r + @options.operations.crossover < @options.operations.reproduce
      "reproduce"
    else
      "mutate"

  # mutates a tree
  _mutate: (tree) =>
    stats = @_treeStats tree

    isTerminal = @_chooseTerminal()

    # extract a point to replace
    max = if isTerminal then stats.terminals else stats.functions

    point = randgen.runif 0, max, true

    replacement = @_generateOne randgen.rpoisson(@options.mutationDepth)

    @_replaceTree tree, point, replacement, isTerminal

  # performs crossover on two trees
  _crossover: (parent1, parent2) =>
    stats1 = @_treeStats parent1
    stats2 = @_treeStats parent2

    # check if we should swap a terminal or a function
    isTerminal = @_chooseTerminal()

    # get the tree size
    if isTerminal
      max1 = stats1.terminals
      max2 = stats2.terminals
    else
      max1 = stats1.functions
      max2 = stats2.functions

    # get crossover points
    point1 = randgen.runif 0, max1, true
    point2 = randgen.runif 0, max2, true

    # grab the subtrees
    subtree1 = @_getTree parent1, point1, isTerminal
    subtree2 = @_getTree parent2, point2, isTerminal

    # and do the replacement
    child1 = @_replaceTree parent1, point1, subtree2, isTerminal
    child2 = @_replaceTree parent2, point2, subtree1, isTerminal

    [child1, child2]

  # get the nth child of parent, depending on if it is a terminal or 
  # a function
  _getTree: (parent, n, isTerminal) =>
    getTree = (_parent) =>
      atLeaf = not @_isFunction _parent

      if atLeaf
        if not isTerminal
          # at a leaf but not looking for a leaf, give false
          [false, null]
        else if n == 0
          # at the correct leaf, return it
          [true, _parent]
        else
          # not at the correct leaf, decrement our counter and move on
          n -= 1
          [false, null]
      else
        if not isTerminal and n == 0
          # found the function we're looking for, return it
          [true, _parent]
        else
          # look through our children for the next node
          n -= 1 if not isTerminal
          for i in [1..._parent.length]
            [found, child] = getTree _parent[i]
            return [found, child] if found
          [false, null]

    [found, child] = getTree parent

    child

  # replace the nth child of parent with replacement
  _replaceTree: (parent, n, replacement, isTerminal) ->
    replaceTree = (_parent) =>
      atLeaf = not @_isFunction _parent

      if atLeaf
        if not isTerminal
          # at a leaf but not looking for a leaf, give false
          [false, _parent]
        else if n == 0
          # at the correct leaf, return it
          [true, replacement]
        else
          # not at the correct leaf, decrement our counter and move on
          n -= 1
          [false, null]
      else
        if not isTerminal and n == 0
          # found the function we're looking for, return it
          [true, clone(replacement)]
        else
          # look through our children for the next node
          n -= 1 if not isTerminal
          for i in [1..._parent.length]
            [found, child] = replaceTree _parent[i]
            if found
              _parent[i] = child
              return [true, _parent]
          [false, null]

    newTree = clone(parent)

    [found, child] = replaceTree newTree

    newTree

  # check if the tree is a function node or a terminal node
  _isFunction: (tree) =>
    _.isArray(tree) and tree.length > 1

  # get the stats from a tree: number of functions, number of terminals
  _treeStats: (tree) =>
    if @_isFunction tree
      # we are a function, not a terminal
      stats =
        functions: 1
        terminals: 0
        depth: 1

      for i in [1...tree.length]
        childStats = @_treeStats tree[i]
        stats.functions += childStats.functions
        stats.terminals += childStats.terminals
        stats.depth = Math.max(stats.depth, childStats.depth + 1)

      stats
    else
      # we're a terminal
      functions: 0
      terminals: 1
      depth: 0

  # calculate the stats
  _calculateStats: =>
    minFitness = undefined
    maxFitness = undefined
    best = 0
    worst = 0

    for i in [0...@fitness.length]
      fitness = @fitness[i]
      minFitness or= fitness
      maxFitness or= fitness

      if fitness < minFitness
        worst = i
        minFitness = fitness

      if fitness > maxFitness
        best = i
        maxFitness = fitness

    minFitness: minFitness
    maxFitness: maxFitness
    avgFitness: @totalFitness / @fitness.length
    best: best
    worst: worst

  # Converts certain terminals into different values:
  # - R: converts to number in [0, 1)
  # - R(a, b): converts to number in [a, b)
  _transformTerminal: (terminal) =>
    match = terminal.match /^r(\((-?\d+(\.\d+)?),\s*(-?\d+(\.\d+)?)\))?$/i

    if match
      # ephemeral constant
      if match[1]
        # we passed some parameters
        min = parseFloat match[2]
        max = parseFloat match[4]
        randgen.runif min, max
      else
        randgen.runif()
    else
      terminal

  # Select individuals proportional to its fitness
  _selectNext: (numIndividuals=1) =>
    # roulette wheel selection
    @point or= 0.0

    values = []
    for i in [1..numIndividuals]
      @point = (@point + randgen.runif 0, @totalFitness) % @totalFitness
      current = @point

      i = 0
      for fitness in @fitness
        if current < fitness
          values.push @population[i]
          break
        else
          i++
          current -= fitness

    values

  # calculates the fitness of all individuals
  _calculateFitness: =>
    @compiled = @population.map (tree) =>
      ls.compile xjson.toLisp(tree), @options.variables

    @fitness = @compiled.map @options.fitness

    @totalFitness = _.reduce @fitness, ((s, i) -> s + i), 0.0
    @currentStats = @_calculateStats()
    @stats.push @currentStats
    return

  _pprint: (tree) =>
    JSON.stringify tree, null, 2

exports.Gin = Gin
