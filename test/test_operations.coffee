gin = require "../gin"
assert = require("chai").assert

g = new gin.Gin()

describe "operations tests", ->
  describe "get subtree", ->
    it "should fetch terminals", (done) ->
      tree = ["+", 2,
                   ["*", "x",
                         ["*", "y", "z"]]]

      result = g._getTree tree, 0, true
      assert.equal 2, result

      result = g._getTree tree, 3, true
      assert.equal "z", result

      result = g._getTree tree, 1, true
      assert.equal "x", result

      result = g._getTree tree, 5, true
      assert.isNull result

      done()

    it "should fetch functions", (done) ->
      tree = ["+", 2,
                   ["*", "x",
                         ["*", "y", "z"]]]

      result = g._getTree tree, 2, false
      assert.equal "*", result[0]

      result = g._getTree tree, 0, false
      assert.equal "+", result[0]

      result = g._getTree tree, 5, false
      assert.isNull result

      done()

  describe "replace subtree", ->
    it "should replace terminals", (done) ->
      tree = ["+", 2,
                   ["*", "x",
                         ["*", "y", "z"]]]

      tree2 = g._replaceTree tree, 2, "s", true

      checkTree2 = g._getTree tree2, 2, true
      assert.equal "s", checkTree2

      # should not affect original
      checkTree = g._getTree tree, 2, true
      assert.equal "y", checkTree

      done()

    it "should replace functions", (done) ->
      tree = ["+", 2,
                   ["*", "x",
                         ["*", "y", "z"]]]

      newTree = ["%", "a", "b"]

      tree2 = g._replaceTree tree, 1, newTree, false

      checkTree2 = g._getTree tree2, 1, false
      assert.equal "%", checkTree2[0]
      checkTree2 = g._getTree tree2, 1, true
      assert.equal "a", checkTree2
      checkTree2 = g._getTree tree2, 2, true
      assert.equal "b", checkTree2

      # should not affect original
      checkTree = g._getTree tree, 1, false
      assert.equal "*", checkTree[0]

      done()
