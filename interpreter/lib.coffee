helpers = require "./helpers"
ensureArguments = helpers.ensureArguments

#######################
#  Built-in functions
#######################

arith = (name, ident, op) ->
  ['defun', name, [], (args) ->
    if op is undefined
      args.reduce ident
    else
      args.reduce op, ident
  ]

exports.lib = [
  arith("+", 0, (a, b) -> a + b),
  arith("-", (a, b) -> a - b),
  arith("*", 1, (a, b) -> a * b),
  arith("/", (a, b) -> a / b),
  arith("%", (a, b) -> a % b),

  # Comparison/logical operators
  ['defun', '=', [], (args) -> args[0] == args[1]],
  ['defun', '>', [], (args) -> args[0] > args[1]],
  ['defun', '>=', [], (args) -> args[0] >= args[1]],
  ['defun', '<', [], (args) -> args[0] < args[1]],
  ['defun', '<=', [], (args) -> args[0] <= args[1]],
  ['defun', 'not', [], (args) -> !args[0]],
  ['defun', 'or', [], (args) -> args[0] || args[1]],
  ['defun', 'and', [], (args) -> args[0] && args[1]],

  # List functions
  ['defun', 'cons', [], (args) -> [ args[0] ].concat(args[1]) ]
  ['defun', 'car', [], (args) ->
    list = args[0]
    if list.length == 0
      throw "Cannot car an empty list!"
    list[0]
  ],
  ['defun', 'cdr', [], ensureArguments (list) -> list.slice 1],
  ["defun", "null?", [], (args) -> args[0].length == 0],
  ['defun', 'list', [], (args) -> args],
  ['defun', 'display', [], (args) -> console.log arg for arg in args; null],

  # Pure-JISP functions
  ['defun', 'map', ["func", "list"],
      ["if", ["null?", "list"],
             ["quote", []],
             ["cons", ["func", ["car", "list"]],
                      ["map", "func", ["cdr", "list"]]]]],

  ['defun', 'reduce', ["func", "init", "list"],
      ["if", ["null?", "list"],
             "init",
             ["reduce", "func",
                        ["func", "init", ["car", "list"]],
                        ["cdr", "list"]]]],

  ['defun', 'filter', ["pred", "list"],
      ["if", ["null?", "list"],
             ["quote", []],
             ["if", ["pred", ["car", "list"]],
                    ["cons", ["car", "list"], ["filter", "pred", ["cdr", "list"]]],
                    ["filter", "pred", ["cdr", "list"]]]]],
]
