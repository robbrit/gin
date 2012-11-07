
/**********************
   Built-in functions
/*********************/

var arith = function(name, ident, op){
  return ['defun', name, [], function(args) {
    return (op === undefined) ?
      args.reduce(ident) :
      args.reduce(op, ident);
  }];
}

exports.lib = [
  arith("+", 0, function(a, b) { return a + b; }),
  arith("-", function(a, b) { return a - b; }),
  arith("*", 1, function(a, b) { return a * b; }),
  arith("/", function(a, b) { return a / b; }),
  arith("%", function(a, b) { return a % b; }),

  // Comparison/logical operators
  ['defun', '=', [], function(args) { return args[0] === args[1]; }],
  ['defun', '>', [], function(args) { return args[0] > args[1]; }],
  ['defun', '>=', [], function(args) { return args[0] >= args[1]; }],
  ['defun', '<', [], function(args) { return args[0] < args[1]; }],
  ['defun', '<=', [], function(args) { return args[0] <= args[1]; }],
  ['defun', 'not', [], function(args) { return !args[0]; }],
  ['defun', 'or', [], function(args) { return args[0] || args[1]; }],
  ['defun', 'and', [], function(args) { return args[0] && args[1]; }],

  // List functions
  ['defun', 'cons', [], function(args) {
    return [args[0]].concat(args[1]);
  }],
  ['defun', 'car', [], function(args) {
    var list = args[0];
    if (list.length == 0){
      throw "Cannot car an empty list!";
    }
    return list[0];
  }],
  ['defun', 'cdr', [], function(args) {
    var list = args[0];
    if (list.length == 0){
      throw "Cannot cdr an empty list!";
    }
    return list.slice(1);
  }],
  ["defun", "null?", [], function(args) {
    return args[0].length == 0;
  }],
  ['defun', 'list', [], function(args) {
    return args;
  }],
  ['defun', 'display', [], function(args){
    for (var i = 0; i < args.length; i++){
      console.log(args[i]);
    }
    return null;
  }],

  // Pure-JISP functions
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
];
