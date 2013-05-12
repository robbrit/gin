_ = require "underscore"

# counts the number of symbols in a sexp
countSymbols = (sexp) ->
  if _.isArray sexp
    _.reduce sexp, ((s, el) -> s + countSymbols(el)), 0
  else
    1

exports.countSymbols = countSymbols
