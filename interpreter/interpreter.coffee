# global scope
exports.globalEnv = {}

# Helper function to merge several objects and return the result
merge = ->
  res = {}
  for key, arg of arguments
    for name, value of arg
      res[name] = value
  res

# Test if something is an array
isArray = (obj) ->
  Object.prototype.toString.call(obj) == '[object Array]'

# A set of special forms. The main difference between these and functions is that
# the arguments are not evaluated when they are passed in, where with functions the
# arguments have all been evaluated
specialForms =
  # Defines a new function in the current scope
  defun: (arr, definingEnvironment) ->
    throw "defun requires at least 3 arguments!" if arr.length <= 2

    funcName = arr[0]
    
    if typeof(arr[2]) == "function"
      # native function - wrap it with a function
      res = (args, callingEnvironment) ->
        evalled = (gin arg, callingEnvironment for arg in args)

        arr[2](evalled)

      definingEnvironment[funcName] = res
    else
      # function defined in gin, create it as a lambda and bind this environment to it.
      # this will automatically handle recursive calls
      definingEnvironment[funcName] =
        specialForms.lambda arr.slice(1), definingEnvironment

    definingEnvironment[funcName]

    # do a comparison
  "if": (arr, env) ->
    throw "if requires at least two arguments!" if arr.length <= 1

    cond = gin arr[0], env

    if cond
      gin arr[1], env
    else if arr[2]
      gin arr[2], env
    else
      null

  # binds a list of names to values and then evaluates some statements
  # under that binding
  let: (arr, env) ->
    bindings = arr[0]
    body = arr.slice 1

    # create a local scope for this function call with arguments bound
    localScope = {}
    for binding in bindings
      localScope[binding[0]] = gin binding[1], env

    localScope = merge env, localScope

    # evaluate all elements, return the last one
    for b in body
      res = gin b, localScope

    res

  # Sets the value of a variable in the environment
  "set!": (arr, env) ->
    env[arr[0]] = gin arr[1], env
    env[arr[0]]

  # quotes something and doesn't eval it
  quote: (arr, env) ->
    arr[0]

  # Opposite of quote: executes the first argument
  "eval": (arr, env) ->
    gin gin(arr[0], env), env

  # throws an exception
  "throw": (arr, env) ->
    throw arr[0]

  # Creates an anonymous function
  lambda: (arr, lexicalEnvironment) ->
    argNames = arr[0]
    body = arr.slice 1
    (args, dynamicEnvironment) ->
      bindings = []
      for i in [0...argNames.length]
        bindings.push [argNames[i], args[i]]

      # This is probably not the best way to do it - the arguments should be evaluated in the dynamic
      # environment, but the body itself should be executed in the lexical environment
      specialForms.let [bindings].concat(body),
        merge lexicalEnvironment, dynamicEnvironment

# Evaluate a sexp in a certain environment
gin = (arr, env) ->
  env = env || exports.globalEnv

  if not isArray arr
    # either a constant or a variable - no string literals in gin (yet)
    if typeof(arr) == 'string'
      if env[arr] is undefined
        throw "Unknown identifier '#{arr}'"
      else
        return env[arr]
    else
      return arr

  # we're an array, evaluate it
  throw "Cannot eval empty list!" if arr.length == 0

  funcName = arr[0]
  args = arr.slice(1)

  if typeof(funcName) == "string" and specialForms[funcName]
    # Evaluate as a special form
    specialForms[funcName] args, env
  else
    # Evaluate the function parameter
    what = gin funcName, env

    if typeof(what) == 'function'
      # what will probably be a lambda expression and will handle
      # the evaluation of the arguments correctly
      what args, env
    else
      what

# Exports the gin interpreter
exports.gin = gin

# Load the standard lib
lib = require("./lib").lib

lib.forEach (sexp) -> gin(sexp)

# Execute a file in the standard environment
exports.exec = (file, env) ->
  fs = require "fs"
  env = env || exports.globalEnv

  fs.readFile file, "utf-8", (err, data) ->
    throw err if err

    # strip out comments
    data = data.replace /\/\/.*?\n/g, ''

    code = JSON.parse data

    code.forEach (sexp) ->
      try
        gin sexp, env
      catch e
        console.error "issue on:", sexp, "\n", env
        throw e
