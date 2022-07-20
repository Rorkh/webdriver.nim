# Package

version       = "0.1.0"
author        = "Rorkh"
description   = "Webdriver library for nim"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 1.6.6"

task docs, "Generate docs":
  rmDir "docs"
  exec "nimble doc --outdir:docs --project --index:on src/webdriver"
