import webdriver, os, osproc
import httpclient, uri, json, tables, base64, strutils

type 
  Session* = object
    id*: string
    url*: string
    driver*: WebDriver

  ProtocolException* = object of WebDriverException

# Session

proc createSession*(self: WebDriver): Session =
  if self.kind == WebDriverKind.External:
    self.url = ("http://localhost:" & self.settings.port).parseUri
    discard startProcess(self.filepath, "", ["-p", self.settings.port])

  let resp = self.client.getContent($(self.url / "status"))
  let parsed = parseJson(resp)

  if parsed["value"]["ready"].isNil():
      let msg = "Readiness message does not follow the spec"
      raise newException(ProtocolException, msg)

  if not parsed["value"]["ready"].getBool():
      raise newException(WebDriverException, "WebDriver is not Ready")

  let sessionReq = %*{"capabilities": self.settings.capabilities}
  let sessionResp = self.client.postContent($(self.url / "session"),
                                                      $sessionReq)

  let parsedid = parseJson(sessionResp)
  if parsedid["value"]["sessionId"].isNil():
      raise newException(ProtocolException, "no sessionId in response")
  
  return Session(id: parsedid["value"]["sessionId"].getStr(), driver: self)

# Navigation

proc navigate*(self: Session, url:string) =
    let requrl = $(self.driver.url / "session" / self.id / "url")
    let obj = %*{"url": url}
    let resp = self.driver.client.postContent(requrl, $obj)

    let respObj = parseJson(resp)
    if respObj["value"].getFields().len != 0:
        raise newException(WebDriverException, $respObj)

proc getCurrentUrl*(self: Session): string =
    let requrl = $(self.driver.url / "session" / self.id / "url")
    let resp = self.driver.client.getContent(requrl)

    let respObj = parseJson(resp)
    let parsedObj = respObj["value"]
    if parsedObj.getFields().len != 0:
        raise newException(WebDriverException, $respObj)

    return parsedObj.getStr()

proc back*(self: Session, count: int = 1) =
    let requrl = $(self.driver.url / "session" / self.id / "back")
    let obj = %*{"":""}
    var i = 0

    while count > i:
        i.inc
        let resp = self.driver.client.postContent(requrl, $obj)
        let respObj = parseJson(resp)
        if respObj["value"].kind != JNull:
            raise newException(WebDriverException, $respObj)

proc forward*(self: Session, count: int = 1) =
    let requrl = $(self.driver.url / "session" / self.id / "forward")
    let obj = %*{"":""}
    var i = 0

    while count > i:
        i.inc
        let resp = self.driver.client.postContent(requrl, $obj)
        let respObj = parseJson(resp)
        if respObj["value"].kind != JNull:
            raise newException(WebDriverException, $respObj)

    
proc refresh*(self: Session) =
    let requrl = $(self.driver.url / "session" / self.id / "refresh")
    let obj = %*{"":""}
    let resp = self.driver.client.postContent(requrl, $obj)

    let respObj = parseJson(resp)
    if respObj["value"].kind != JNull:
        raise newException(WebDriverException, $respObj)

proc getTitle*(self: Session): string =
    let requrl = $(self.driver.url / "session" / self.id / "title")
    let resp = self.driver.client.getContent(requrl)

    let respObj = parseJson(resp)
    
    return respObj["value"].getStr() 

# Contexts

proc getWindowHandle*(self: Session): string =
    let requrl = $(self.driver.url / "session" / self.id / "window")
    let resp = self.driver.client.getContent(requrl)
    
    let respObj = parseJson(resp)

    return respObj["value"].getStr() 

proc closeWindow*(self: Session) =
    let requrl = $(self.driver.url / "session" / self.id / "window")
    let resp = self.driver.client.deleteContent(requrl)

    let respObj = parseJson(resp)

    if respObj["value"].getStr() != "":
        raise newException(WebDriverException, $respObj)

proc switchWindow*(self: Session, handle: string) =
  let requrl = $(self.driver.url / "session" / self.id / "window")
  let obj = %*{"handle": handle}

  discard self.driver.client.postContent(requrl, $obj)

proc getWindowHandles*(self: Session): seq =
    let requrl = $(self.driver.url / "session" / self.id / "window" / "handles")
    let resp = self.driver.client.getContent(requrl)

    let respObj = parseJson(resp)

    return respObj["value"].getElems()

proc newTab*(self: Session): string =
  let requrl = $(self.driver.url / "session" / self.id / "window" / "new")
  let obj = %*{"type": "tab"}
  let resp = self.driver.client.postContent(requrl, $obj)

  let respObj = parseJson(resp)

  return respObj["value"]["handle"].getStr()

proc newWindow*(self: Session): string =
  let requrl = $(self.driver.url / "session" / self.id / "window" / "new")
  let obj = %*{"type": "window"}
  let resp = self.driver.client.postContent(requrl, $obj)

  let respObj = parseJson(resp)

  return respObj["value"]["handle"].getStr()

proc maximize*(self: Session) =
    let requrl = $(self.driver.url / "session" / self.id / "window" / "maximize")
    let obj = %*{"":""}

    discard self.driver.client.postContent(requrl, $obj)

proc minimize*(self: Session) =
    let requrl = $(self.driver.url / "session" / self.id / "window" / "minimize")
    let obj = %*{"":""}

    discard self.driver.client.postContent(requrl, $obj)

proc fullScreen*(self: Session) =
    let requrl = $(self.driver.url / "session" / self.id / "window" / "fullscreen")
    let obj = %*{"":""}

    discard self.driver.client.postContent(requrl, $obj)

proc getPageSource*(self: Session): string =
    let requrl = $(self.driver.url / "session" / self.id / "source")
    let resp = self.driver.client.getContent(requrl)

    let respObj = parseJson(resp)

    return respObj["value"].getStr()

proc getAllCookies*(self: Session): seq =
    let requrl = $(self.driver.url / "session" / self.id / "cookie")
    let resp = self.driver.client.getContent(requrl)

    let respObj = parseJson(resp)

    return respObj["value"].getElems()

proc addCookies*(self: Session, toadd: seq) =
    let requrl = $(self.driver.url / "session" / self.id / "cookie")

    for i in low(toadd)..high(toadd):
        let obj = %*{"cookie": %*toadd[i]}
        let resp = self.driver.client.postContent(requrl, $obj)
        
        let respObj = parseJson(resp)

        if respObj["value"].kind != JNull:
            raise newException(WebDriverException, $respObj)

proc deleteAllCookies*(self: Session) =
    let requrl = $(self.driver.url / "session" / self.id / "cookie")
    let resp = self.driver.client.deleteContent(requrl)

    let respObj = parseJson(resp)

    if respObj["value"].kind != JNull:
        raise newException(WebDriverException, $respObj)
    
proc takeScreenshot*(self: Session, filename: string) =
    let requrl = $(self.driver.url / "session" / self.id / "screenshot")
    let resp = self.driver.client.getContent(requrl)

    let respObj = parseJson(resp)

    let decoded = decode(respObj["value"].getStr())
    writeFile(filename, decoded)

proc takeElementScreenshot*(self: Session, elementid: string, filename: string) =
    let requrl = $(self.driver.url / "session" / self.id / "element" / elementid / "screenshot")
    let resp = self.driver.client.getContent(requrl)

    let respObj = parseJson(resp)

    let decoded = decode(respObj["value"].getStr())
    writeFile(filename, decoded)

proc executeScript*(self: Session, script: string) =
    let requrl = $(self.driver.url / "session" / self.id / "execute" / "sync")
    let obj = %*{"script": script, "args": []}

    let resp = self.driver.client.postContent(requrl, $obj)

    let respObj = parseJson(resp)

    if respObj["value"].kind != JNull:
        raise newException(WebDriverException, $respObj)

proc executeAsyncScript*(self: Session, script: string) =
    let requrl = $(self.driver.url / "session" / self.id / "execute" / "async")
    let obj = %*{"script": script, "args": []}

    let resp = self.driver.client.postContent(requrl, $obj)

    let respObj = parseJson(resp)

    if respObj["value"].kind != JNull:
        raise newException(WebDriverException, $respObj)

proc dissmissAlert*(self: Session) =
    let requrl = $(self.driver.url / "session" / self.id / "alert" / "dismiss")
    let obj = %*{"":""}

    let resp = self.driver.client.postContent(requrl, $obj)

    let respObj = parseJson(resp)

    if respObj["value"].kind != JNull:
        raise newException(WebDriverException, $respObj)

proc acceptAlert*(self: Session) =
    let requrl = $(self.driver.url / "session" / self.id / "alert" / "accept")
    let obj = %*{"":""}

    let resp = self.driver.client.postContent(requrl, $obj)

    let respObj = parseJson(resp)

    if respObj["value"].kind != JNull:
        raise newException(WebDriverException, $respObj)

proc alertText*(self: Session): string =
    let requrl = $(self.driver.url / "session" / self.id / "alert" / "text")
    
    let resp = self.driver.client.getContent(requrl)

    let respObj = parseJson(resp)

    return respObj["value"].getStr()

proc findElement*(self: Session, use: string, value: string): string = 
    let requrl = $(self.driver.url / "session" / self.id / "element")
    let obj = %*{"using": use, "value": value}

    let resp = self.driver.client.postContent(requrl, $obj)
    #echo resp
    let elementid = resp.split('"')[5] #Shitty workaround for the parsing
    return elementid

proc click*(self: Session, elementid: string) =
    let requrl = $(self.driver.url / "session" / self.id / "element" / elementid / "click")
    let obj = %*{"":""}

    let resp = self.driver.client.postContent(requrl, $obj)
    
    let respObj = parseJson(resp)
    if respObj["value"].kind != JNull:
        raise newException(WebDriverException, $respObj)

proc sendKeys*(self: Session, elementid: string, text: string) =
    let requrl = $(self.driver.url / "session" / self.id / "element" / elementid / "value")
    let obj = %*{"text":text}

    let resp = self.driver.client.postContent(requrl, $obj)
    
    let respObj = parseJson(resp)
    if respObj["value"].kind != JNull:
        raise newException(WebDriverException, $respObj)

proc clear*(self: Session, elementid: string) =
    let requrl = $(self.driver.url / "session" / self.id / "element" / elementid / "clear")
    let obj = %*{"":""}

    let resp = self.driver.client.postContent(requrl, $obj)

    let respObj = parseJson(resp)
    if respObj["value"].kind != JNull:
        raise newException(WebDriverException, $respObj)
