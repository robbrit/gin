[
  //
  // Tests
  //
  ["defun", "fact", ["n"], 
      ["defun", "factn", ["a", "i"],
        ["if", [">", "i", "n"],
          "a",
          ["factn", ["*", "a", "i"],
                    ["+", "i", 1],
                    "n"]]],
      ["factn", 1, 1]],

  ["display", ["+", ["-", 2, 3], 4]],
  ["display", ["%", 4, 3]],
  ["display", ["quote", ["+", 1, 2]]],
  ["display", ["eval", ["+", 1, 2]]],
  ["display", ["eval", ["quote", ["+", 1, 2]]]],
  ["display", ["list", 1, ["+", 2, 1], 3]],
  ["display", ["car", ["list", 1, 2, 3]]],
  ["display", ["cdr", ["list", 1, 2, 3]]],
  ["display", [["lambda", ["x"], ["*", "x", 2]], 3]],
  ["display", ["fact", 3]],
  ["display", [["lambda", ["x"], ["*", "x", 2]],
                    ["car", ["list", 1, 2, 3]]]],

  // test higher-order functions
  ["display", ["map",
        ["lambda", ["x"], ["*", "x", 2]],
        ["list", 1, 2, 3]]],

  ["display", ["reduce",
        ["lambda", ["a", "b"], ["+", "a", "b"]],
        0,
        ["list", 1, 2, 3, 4]]],

  ["display", ["filter",
        ["lambda", ["a"], ["=", 0, ["%", "a", 2]]],
        ["list", 1, 2, 3, 4]]],

  // test closures
  ["defun", "adder", ["a"],
      ["lambda", ["b"], ["+", "a", "b"]]],

  ["let", [["add2", ["adder", 2]],
                ["add5", ["adder", 5]]],
            ["display", ["add2", 4]],
            ["display", ["add5", -2]],
            ["display", ["add2", 8]],
            ["display", ["add5", 12]]]
]
