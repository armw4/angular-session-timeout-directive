angular
.module 'core.uri', []
.service 'uri', ->
  @parse = (uri) ->
    parser      = document.createElement('a')
    parser.href = uri

    protocol : parser.protocol
    hostname : parser.hostname
    port     : parser.port
    pathname : parser.pathname
    search   : parser.search
    hash     : parser.hash
    host     : parser.host

  @isRequestForFile = (path) ->
    /(\..+)$/.test path

  @
