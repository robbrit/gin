exports.ensureArguments = (fn) ->
  (args) ->
    list = args[0]
    if list.length == 0
      throw "Cannot cdr an empty list!"
    fn list
