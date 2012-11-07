var gin = require("./interpreter/interpreter"),
    lib = require("./interpreter/lib"),
    fs = require("fs");

if (process.argv.length < 2){
  console.log("gin: no input files.");
}

var file = process.argv[2];

gin.exec(file);
