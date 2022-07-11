# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest

import webdriver
import json

test "run":
  #echo findExe("ms")
  let driver: WebDriver = newChromeWebDriver()
  let session = driver.createSession()

  session.navigate("https://github.com/login")
  let handle = session.getWindowHandle()

  let window = session.newTab()
  session.switchWindow(handle)

  echo $session.getWindowHandles()

  while true:
    discard