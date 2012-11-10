# Gets a random positive number less than n
exports.randInt = (n) -> Math.floor Math.random() * n

# Gets a random element from a list
exports.randList = (list) -> list[exports.randInt list.length]

# Converts a 
exports.convertMessage = (message) -> message
  #return JSON.parse(unescape(encodeURIComponent(JSON.stringify(message))))

exports.generate = (terminals, functions, depth, options) ->
  if depth == 0 or Math.random() < options.terminalChance
    # choose a terminal
    res = exports.randList terminals

    # random constant
    if res == "R"
      Math.random()
    else
      res
  else
    func = exports.randList functions

    [
      func[0],
      for i in [1..func[1]]
        exports.generate terminals, functions, depth - 1, options
    ]
