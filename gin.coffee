gin = require "./interpreter/interpreter"
lib = require "./interpreter/lib"
helpers = require "./helpers"
amqp = require "amqp"
memcache = require "memcache"
_ = require "underscore"

# connect to AMQP
connection = amqp.createConnection
  host: "localhost"

exchange = null

# connect to memcache
mc = new memcache.Client 11211, "localhost"

args =
  # Odds of choosing from the terminal set
  terminalChance: 0.4
  # Maximum depth of an initial program
  maxDepth: 5

go = ->
  # First thing - an initializer which accepts a specification for the
  # genetic algorithm run. Arguments:
  # - tag - Name that this run of gin will be called
  # - numGenerations
  # - batchSize
  # - numBatches
  # - terminals
  # - functions
  # - fitness
  #
  # Note: population size = batchSize * numBatches
  # 
  connection.queue "initalize",
    autoDelete: false
  , (queue) ->
    queue.bind "gin", "initialize"
    queue.subscribe (message) ->
      message = helpers.convertMessage message
      console.log "initialize", message

      # save the basic info for this machine
      machine_key = "gin_#{message.tag}"

      mc.set machine_key, message, (err, res) ->
        for i in [1..message.numBatches]
          exchange.publish "generate",
            tag: message.tag
            batchNum: i
            batchSize: message.batchSize
            terminals: message.terminals
            functions: message.functions

  # Generate the individuals for a run. Arguments:
  # - tag
  # - batchSize
  # - batchNum
  # - terminals
  # - functions
  connection.queue "generate",
    autoDelete: false
  , (queue) ->
    # Little function that generates a random program from a set of terminals
    # and functions
    queue.bind "gin", "generate"
    queue.subscribe (message) ->
      console.log "generating"

      # generate us some individuals
      individuals = for i in [1..message.batchSize]
        helpers.generate message.terminals, message.functions, args.maxDepth,
          args

      console.log "individuals", JSON.stringify(individuals)

      # save it in memcache
      batchKey = "gin_#{message.tag}_#{message.batchNum}"

      mc.set batchKey, JSON.stringify(individuals), (err, res) ->
        # trigger the fitness check
        exchange.publish "fitness_check",
          tag: message.tag
          batchNum: message.batchNum


  # Evaluate the fitness for the individuals. Arguments:
  # - tag
  # - fitness
  #connection.queue "fitness_check", (queue) ->
    #queue.bind "gin", "fitness_check"
    #queue.subscribe (message) ->
      # evaluate the fitness of all the individuals

connection.on "ready", ->
  # Connect to the gin exchange
  exchange = connection.exchange "gin",
    type: "topic"
    durable: true
  , (exch) ->
    console.info "Connected to queues."

    # connect to memcache
    mc.on "connect", ->
      console.info "Connected to memcache."
      do go

    do mc.connect
