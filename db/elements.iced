exports.update = (pid, owner, data, fn) =>
  data = data.element
  canvas = data.canvasId
  eid = data.elementId
  element = {}
  element.project = pid
  element.owner = owner
  element.canvasId = canvas
  element.time = Date.now()
  element.data = JSON.stringify(data)
  return @client.exists "elements:#{eid}", (err, exists) =>
    @client.hmset "elements:#{eid}", element, @tools.logError
    unless exists # creating new element
      @client.rpush "canvases:#{canvas}:elements", eid if canvas
      return @tools.asyncOpt fn, err, element
    return @tools.asyncOpt fn, err, element

exports.delete = (eid, fn) =>
  @db.elements.findById eid, (err, element) =>
    if err or not element
      return @tools.asyncOpt fn, err, null
    @client.del "elements:#{eid}", fn
    @client.lrem "canvases:#{element.canvasId}:elements", 0, eid
    return @tools.asyncOpt fn, null, eid

exports.findById = (eid, fn) =>
  @client.hgetall "elements:#{eid}", fn

exports.index = (cid, fn) =>
  @client.lrange "canvases:#{cid}:elements", 0, -1, (err, array) =>
    return @tools.asyncOpt fn, null, [] if not array or not array.length
    if not err
      elements = []
      return @tools.asyncParallel array, (eid) =>
        @client.hgetall "elements:#{eid}", (err, element) =>
          elementData = JSON.parse(element.data)
          elementData.number = element.number
          return @tools.asyncOpt fn, err, [] if err
          elements.push elementData
          return @tools.asyncDone array, =>
            return @tools.asyncOpt fn, null, elements
    return @tools.asyncOpt fn, err, []

exports.getCanvas = (eid, fn) =>
  @client.hget "elements:#{eid}", 'canvasId', fn
