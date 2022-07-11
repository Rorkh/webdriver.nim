import httpclient, uri, os

type
  # TODO: Remove
  WebDriverKind* = enum
    External
    Remote

  WebDriver* = ref object
    case kind*: WebDriverKind
      of External: filepath*: string
      of Remote: discard
    url*: Uri
    client*: HttpClient

  WebDriverException* = object of CatchableError

# Remote connection

proc newRemoteWebDriver*(url: string = "http://localhost:9515"): WebDriver =
  return WebDriver(kind: Remote, url: url.parseUri, client: newHttpClient())

# Internal drivers

proc findDriver(driver: string): string =
  let filepath = findExe(driver)

  if filepath == "":
    raise newException(WebDriverException, "Cannot find " & driver & " webdriver")

  return filepath

proc newChromeWebDriver*(): WebDriver =
  return WebDriver(kind: External, filepath: findDriver("chromedriver"), client: newHttpClient())

proc newGeckoWebDriver*(): WebDriver =
  return WebDriver(kind: External, filepath: findDriver("geckodriver"), client: newHttpClient())

proc newEdgeWebDriver*(): WebDriver =
  return WebDriver(kind: External, filepath: findDriver("msedgedriver"), client: newHttpClient())