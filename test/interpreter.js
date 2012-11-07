var assert = require("assert");
var gin = require("../interpreter/interpreter").gin;

describe("arithmetic functions", function(){
  it("should add properly", function(){
    assert.equal(7,  gin(["+", 2, 5]));
    assert.equal(-2, gin(["+", 2, -4]));
    assert.equal(23, gin(["+", 12, -2, 7, 6]));
  });

  it("should subtract properly", function(){
    assert.equal(3,  gin(["-", 7, 4]));
    assert.equal(-5, gin(["-", 7, 4, 8]));
  });

  it("should multiply properly", function(){
    assert.equal(21, gin(["*", 3, 7]));
    assert.equal(0,  gin(["*", 2, 3, 2, -12, 0]));
  });

  it("should compute factorials", function(){
    gin(["defun", "fact", ["n"], 
      ["defun", "factn", ["a", "i"],
        ["if", [">", "i", "n"],
          "a",
          ["factn", ["*", "a", "i"],
                    ["+", "i", 1],
                    "n"]]],
      ["factn", 1, 1]]);

    assert.equal(24,  gin(["fact", 4]));
    assert.equal(720, gin(["fact", 6]));
  });
});

describe("list functions", function(){
  it("list - should create a list", function(){
    assert.deepEqual([1, 2, 3], gin(["list", 1, 2, 3]));
    assert.deepEqual([1, 3, 3], gin(["list", 1, ["+", 2, 1], 3]));
    assert.deepEqual([1, ["+", 2, 1], 3],
                  gin(["list", 1, ["quote", ["+", 2, 1]], 3]));
    assert.deepEqual([], gin(["list"]));
  });

  it("car - should get the first element", function(){
    assert.equal(1, gin(["car", ["list", 1, 2, 3]]));
    assert.equal(2, gin(["car", ["car", ["list", ["list", 2, 1, 3]]]]));
    assert.throws(function(){
      gin(["car", ["list"]]);
    });
  });

  it("cdr - should get the rest of the list", function(){
    assert.deepEqual([2, 3], gin(["cdr", ["list", 1, 2, 3]]));
    assert.deepEqual([3], gin(["cdr", ["cdr", ["list", 1, 2, 3]]]));
    assert.deepEqual([], gin(["cdr", ["list", 1]]));
    assert.throws(function(){
      gin(["cdr", ["list"]]);
    });
  });

  it("null? - should check empty lists", function(){
    assert(gin(["null?", ["list"]]));
    assert(!gin(["null?", ["list", 1]]));
    assert(!gin(["null?", 1]));
    assert(!gin(["null?", ["list", ["list"]]]));
  });

  /*
  ["display", ["eval", ["+", 1, 2]]],
  ["display", ["eval", ["quote", ["+", 1, 2]]]],
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
            ["display", ["add5", 12]]]*/
});
