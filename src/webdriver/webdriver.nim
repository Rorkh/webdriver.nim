import std/[tables, httpclient, uri, os]

type
  # TODO: Remove
  WebDriverKind* = enum
    External
    Remote

  WebDriverSettings* = ref object
    port*: string
    capabilities*: Table[string, string]

  WebDriver* = ref object
    case kind*: WebDriverKind
      of External: filepath*: string
      of Remote: discard
    url*: Uri
    client*: HttpClient
    settings*: WebDriverSettings

  WebDriverException* = object of CatchableError

# Settings

proc newWebDriverSettings*(port: string = "9515"): WebDriverSettings =
  return WebDriverSettings(port: port, capabilities: initTable[string, string]())

proc newWebDriverSettings*(port: string = "9515", capabilites: Table[string, string]): WebDriverSettings =
  return WebDriverSettings(port: port, capabilities: capabilites)

# Remote connection

proc newRemoteWebDriver*(url: string = "http://localhost:9515"): WebDriver =
  return WebDriver(kind: Remote, url: url.parseUri, client: newHttpClient())

# Internal drivers

proc findDriver(driver: string): string =
  let filepath = findExe(driver)

  if filepath == "":
    raise newException(WebDriverException, "Cannot find " & driver & " webdriver")

  return filepath

proc newChromeWebDriver*(settings: WebDriverSettings): WebDriver =
  return WebDriver(kind: External, filepath: findDriver("chromedriver"), client: newHttpClient(), settings: settings)

proc newChromeWebDriver*(): WebDriver =
  return WebDriver(kind: External, filepath: findDriver("chromedriver"), client: newHttpClient(), settings: newWebDriverSettings())

proc newGeckoWebDriver*(settings: WebDriverSettings): WebDriver =
  return WebDriver(kind: External, filepath: findDriver("geckodriver"), client: newHttpClient(), settings: settings)

proc newGeckoWebDriver*(): WebDriver =
  return WebDriver(kind: External, filepath: findDriver("geckodriver"), client: newHttpClient(), settings: newWebDriverSettings())

proc newEdgeWebDriver*(settings: WebDriverSettings): WebDriver =
  return WebDriver(kind: External, filepath: findDriver("msedgedriver"), client: newHttpClient(), settings: settings)

proc newEdgeWebDriver*(): WebDriver =
  return WebDriver(kind: External, filepath: findDriver("msedgedriver"), client: newHttpClient(), settings: newWebDriverSettings())