Spine = require('spine')
{assert} = require('./util')

class ResourceClient
  constructor: (options) ->
    @sync = options.sync
    @appContext = options.appContext
    
    @base = null
    @headers = {}
    @routes = null
    @IDField = "id"
    @dataCoding = "form" # "json"

  fetch: (model, options = {}) ->
    console.log "[ResourceClient] Fetching with options", options
    collection = model.className
    path = @_findPath(collection, "index", options.pathParams)
    ids = []
    @_request path, options.params, (result) =>
      items = @itemsFromResult(result)
      unless items?
        console.log "[ResourceClient] Items not found in response", result
        return
      console.log "[ResourceClient] Found #{items.length} items"
      for item in items
        item.id = item[@IDField]
        assert item.id, "[ResourceClient] There's no field '#{@IDField}' that is configured as IDField in incoming object"
        ids.push(item.id)
        uri = {collection: collection, id: item.id}
        options.updateData(item) if options.updateData?
        @sync.updateOrCreate(uri, item)
        @sync.markURISynced(uri)
      @_removeObjectsNotInList(collection, ids) if options.remove == true
      console.log "[ResourceClient] Finished fetch"
  
  _removeObjectsNotInList: (collection, ids) ->
    uris = @appContext.allURIs(collection)
    for uri in uris
      isInList = ids.indexOf(uri.id) != -1
      unless isInList
        console.log "[ResourceClient] Local id #{uri.id} wasn't retrieved, destroying."
        @appContext.destroy(uri)
  
  itemsFromResult: (result) ->
    result

  syncURI: (uri, action) ->
    console.log "Syncing object", uri
    path = @_findPath(uri.collection, action)
    data = @appContext.dataForURI(uri)
    delete data[@IDField] # TODO: Better solution
    @_request path, data, (result) =>
      result.id = result[@IDField] # TODO: Something smarter
      assert result.id, "[ResourceClient] There's no field '#{@IDField}' that is configured as IDField in incoming object"
      # Handle id change case
      @sync.updateOrCreate(uri, result)
      @sync.markURISynced(uri)

  _findPath: (collection, action, params = {}) ->
    console.log "finding path", params
    assert @routes[collection], "No route found for #{collection}"
    path = @routes[collection][action]
    assert path, "No route found for #{collection}/#{action}"
    [method, path] = path.split(" ")
    if params?
      path = path.replace(":#{param}", value) for param, value of params
    {method: method, path: path}
    

  _request: (path, params, callback) ->
    url = @base + path.path
    method = path.method
    data = params or {}
    contentType = "application/x-www-form-urlencoded"
    if @dataCoding == "json"
      data = JSON.stringify(data)
      contentType = "application/json" 

    success = (result) ->
      callback(result)
    error = (res, err) =>
      return @sync.didFailAuth() if res.status == 401
      console.log "Fetch failed", res, err
    
    $.ajax url, {type: method, data: data, dataType: "json", success: success, error: error, headers: @headers, contentType: contentType}
  
  addHeader: (header, value) ->
    @headers[header] = value

module.exports = ResourceClient