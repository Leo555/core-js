require! {
  '../library/fn/promise': Promise
  './config': {list, libraryBlacklist, banner}
  fs: {readFile, writeFile, unlink}
  path: {basename, dirname, join}
  webpack, temp
}

module.exports = ({modules = [], blacklist = [], library = no, umd = on})->
  resolve, reject <~! new Promise _
  let @ = modules.reduce ((memo, it)-> memo[it] = on; memo), {}
    for ns of @
      if @[ns]
        for name in list
          if name.indexOf("#ns.") is 0
            @[name] = on

    if library => blacklist ++= libraryBlacklist
    for ns in blacklist
      for name in list
        if name is ns or name.indexOf("#ns.") is 0
          @[name] = no

    TARGET = temp.path {suffix: '.js'}

    err, info <~! webpack do
      entry: list.filter(~> @[it]).map ~>
        if library => join __dirname, '..', 'library', 'modules', it
        else join __dirname, '..', 'modules', it
      output:
        path: dirname TARGET
        filename: basename "./#TARGET"
    if err => return reject err

    err, script <~! readFile TARGET
    if err => return reject err

    err <~! unlink TARGET
    if err => return reject err

    if umd
      exportScript = """
        // CommonJS export
        if (typeof module != 'undefined' && module.exports) module.exports = __e;
        // RequireJS export
        else if (typeof define == 'function' && define.amd) define(function () { return __e; });
        // Export to global object
        else __g.core = __e;
        """
    else
      exportScript = ""

    resolve """
      #banner
      !function(__e, __g, undefined){
      'use strict';
      #script
      #exportScript
      }(1, 1);
      """