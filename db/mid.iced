exports.isMember = (id, pid, fn) =>
  @client.sismember "projects:#{pid}:users", id, fn

exports.isFileInProject = (fid, pid, fn) =>
  @client.sismember "projects:#{pid}:files", fid, fn

exports.isOwner = (id, pid, fn) =>
  @client.hget "projects:#{pid}", 'owner', (err, val) =>
    if  not err and val is id
      return @tools.asyncOpt fn, null, yes
    return @tools.asyncOpt fn, err, no

exports.isInvited = (id, aid, fn) =>
  @client.hget "activities:#{aid}", 'owner', (err, val) =>
    if not err and val is id
      return @tools.asyncOpt fn, null, yes
    return @tools.asyncOpt fn, err, no
