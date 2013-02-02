gin = require "./interpreter/interpreter"
lib = require "./interpreter/lib"
helpers = require "./helpers"
_ = require "underscore"

console.log gin.gin ["defun", "fact", ["n"],
      ["defun", "factn", ["a", "i"],
        ["if", [">", "i", "n"],
          "a",
          ["factn", ["*", "a", "i"],
                    ["+", "i", 1],
                    "n"]]],
      ["factn", 1, 1]]

console.log gin.gin ["fact", 5]
