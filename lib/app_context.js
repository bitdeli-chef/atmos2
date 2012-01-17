(function() {
  var AppContext;

  String.prototype.underscorize = function() {
    return this.replace(/([A-Z])/g, function(letter) {
      return ("_" + (letter.toLowerCase())).substr(1);
    });
  };

  AppContext = (function() {

    function AppContext() {
      this._models = {};
    }

    AppContext.prototype.exists = function(uri) {
      var model;
      model = this._modelForURI(uri);
      return !!model.exists(uri.id);
    };

    AppContext.prototype.create = function(uri, data) {
      var model, record;
      model = this._modelForURI(uri);
      console.log("Creating new record for ", model);
      record = new model(data);
      if (uri.id != null) record.id = uri.id;
      record.save();
      return uri.id = record.id;
    };

    AppContext.prototype.update = function(uri, data) {
      var record;
      record = this._findByURI(uri);
      record.updateAttributes(data);
      return record.save();
    };

    AppContext.prototype.relation = function(name, sourceURI, targetURI) {
      var hash, source, target;
      source = this._findByURI(sourceURI);
      target = this._findByURI(targetURI);
      hash = {};
      hash[name] = target;
      source.updateAttributes(hash);
      return source.save();
    };

    AppContext.prototype._findByURI = function(uri) {
      var model;
      model = this._modelForURI(uri);
      return model.find(uri.id);
    };

    AppContext.prototype._modelForURI = function(uri) {
      var model;
      model = this._models[uri.collection];
      if (!model) {
        console.log("Initializing model", model);
        model = require("models/" + (uri.collection.underscorize()));
        model.fetch();
        this._models[uri.collection] = model;
      }
      return model;
    };

    return AppContext;

  })();

  module.exports = AppContext;

}).call(this);