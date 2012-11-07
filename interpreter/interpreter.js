// global scope
var globalEnv = {};

// Helper function to merge several objects and return the result
function merge(){
  var res = {};
  for (var i = 0; i < arguments.length; i++){
    for (var name in arguments[i]){
      res[name] = arguments[i][name];
    }
  }
  return res;
}

function isArray(obj) { return Object.prototype.toString.call(obj) === '[object Array]'; }

// A set of special forms. The main difference between these and functions is that
// the arguments are not evaluated when they are passed in, where with functions the
// arguments have all been evaluated
var specialForms = {
  // Defines a new function in the current scope
  defun: function(arr, definingEnvironment){
    if (arr.length <= 2){
      throw "defun requires at least 3 arguments!";
    }
    var funcName = arr[0];

    if (typeof(arr[2]) == "function"){
      // native function - wrap it with a function
      definingEnvironment[funcName] = function(args, callingEnvironment){
        var evalled = new Array(args.length);
        for (var i = 0; i < args.length; i++){
          evalled[i] = gin(args[i], callingEnvironment);
        }
        return arr[2](evalled);
      }
    } else {
      // function defined in JISP, create it as a lambda and bind this environment to it.
      // this will automatically handle recursive calls
      definingEnvironment[funcName] = specialForms.lambda(arr.slice(1), definingEnvironment);
    }
    return null;
  },

  // do a comparison
  "if": function(arr, env){
    if (arr.length <= 1){
      throw "if requires at least two arguments!";
    }

    var cond = gin(arr[0], env);

    if (cond){
      return gin(arr[1], env);
    } else if (arr[2]){
      return gin(arr[2], env);
    } else {
      return null;
    }
  },

  // binds a list of names to values and then evaluates some statements
  // under that binding
  let: function(arr, env){
    var bindings = arr[0];
    var body = arr.slice(1);

    // create a local scope for this function call with arguments bound
    var localScope = {};
    for (var i = 0; i < bindings.length; i++){
      localScope[bindings[i][0]] = gin(bindings[i][1], env);
    };
    localScope = merge(env, localScope);

    // evaluate all elements, return the last one
    var result;
    for (var i = 0; i < body.length; i++){
      result = gin(body[i], localScope);
    }
    return result;
  },

  // Sets the value of a variable in the environment
  "set!": function(arr, env){
    env[arr[0]] = gin(arr[1], env);
    return env[arr[0]];
  },

  // quotes something and doesn't eval it
  quote: function(arr, env){
    return arr[0];
  },

  // Opposite of quote: executes the first argument
  "eval": function(arr, env){
    return gin(gin(arr[0], env), env);
  },

  // throws an exception
  "throw": function(arr, env){
    throw arr[0];
  },

  // Creates an anonymous function
  lambda: function(arr, lexicalEnvironment){
    var argNames = arr[0];
    var body = arr.slice(1);
    return function(args, dynamicEnvironment){
      var bindings = [];
      for (var i = 0; i < argNames.length; i++){
        bindings.push([argNames[i], args[i]]);
      }
      // This is probably not the best way to do it - the arguments should be evaluated in the dynamic
      // environment, but the body itself should be executed in the lexical environment
      return specialForms.let([bindings].concat(body), merge(lexicalEnvironment, dynamicEnvironment));
    };
  }
}

// Evaluate a sexp in a certain environment
var gin = function(arr, env){
  env = env || globalEnv;

  if (!isArray(arr)){
    // either a constant or a variable - no string literals in gin (yet)
    if (typeof(arr) == 'string'){
      if (env[arr] === undefined){
        throw "Unknown identifier '" + arr + "'";
      } else {
        return env[arr];
      }
    } else {
      return arr;
    }
  }

  // we're an array
  if (arr.length == 0){
    throw "Cannot eval empty list!";
  }

  var funcName = arr[0];
  var args = arr.slice(1);

  if (typeof(funcName) == "string" && specialForms[funcName]){
    // Evaluate as a special form
    return specialForms[funcName](args, env);
  } else {
    // Evaluate the function parameter
    var what = gin(funcName, env);

    if (typeof(what) === 'function'){
      // what will probably be a lambda expression and will handle
      // the evaluation of the arguments correctly
      return what(args, env);
    } else {
      return what;
    }
  }
}

// Exports the gin interpreter
exports.gin = gin;

// Load the standard lib
var lib = require("./lib").lib;

lib.forEach(function(sexp){
  gin(sexp);
});

// Execute a file in the standard environment
exports.exec = function(file, env){
  var fs = require("fs");
  env = env || globalEnv;

  fs.readFile(file, "utf-8", function(err, data){
    if (err) {
      throw err;
    }

    // strip out comments
    data = data.replace(/\/\/.*?\n/g, '');

    var code = JSON.parse(data);

    code.forEach(function(sexp){
      try {
        gin(sexp, env);
      } catch (e){
        console.error("issue on:", sexp, "\n", env);
        throw e;
      }
    });
  });
};
