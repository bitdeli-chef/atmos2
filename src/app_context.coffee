String.prototype.underscorize = ->
	@replace /([A-Z])/g, (letter) -> "_#{letter.toLowerCase()}".substr(1)

class AppContext
  constructor: ->
    @_models = {}
  
  exists: (uri) ->
    model = @_modelForURI(uri)
    !!model.exists(uri.id)
  
  updateOrCreate: (uri, data) ->
    if @exists(uri)
      @update uri, data
    else
      @create uri, data
  
  create: (uri, data) ->
    model = @_modelForURI(uri)
    console.log "Creating new record for ", uri
    record = new model(data)
    record.id = uri.id if uri.id?
    record.save()
    uri.id = record.id
    model.fetch()
  
  update: (uri, data) ->
    record = @objectAtURI(uri)
    record.updateAttributes(data)
    record.save()
  
  changeID: (uri, id) ->
    record = @objectAtURI(uri)
    console.log "changing id from #{record.id} to #{id}"
    record.changeID(id)
  
  relation: (name, sourceURI, targetURI) ->
    source = @objectAtURI(sourceURI)
    target = @objectAtURI(targetURI)
    hash = {}
    hash[name] = target
    source.updateAttributes(hash)
    source.save()
  
  objectAtURI: (uri) ->
    model = @_modelForURI(uri)
    model.find(uri.id)
  
  dataForURI: (uri) ->
    @objectAtURI(uri).attributes()
  
  _modelForURI: (uri) ->
    model = @_models[uri.collection]
    unless model
      console.log "Initializing model", uri.collection
      model = require("models/#{uri.collection.underscorize()}")
      model.fetch()
      @_models[uri.collection] = model
    model
  
  objectURI: (object) ->
    {collection: object.constructor.className, id: object.id}
  
module.exports = AppContext