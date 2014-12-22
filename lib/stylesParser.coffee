fs = require 'fs'
walk = require 'walk'
path = require 'path'
Q = require 'q'
parse = require 'css-parse'
_ = require 'lodash'

class SSParser

  constructor: ->
    @classes = []
    @ids = []
    @ssFiles = []
    defered = Q.defer()
    @loaded = defered.promise;

    prjDir = atom.project.getPaths()

    @getSSFiles(prjDir).then (files)=>
      @ssFiles = files
      for i in [0...files.length]
        console.log 'parsing file', i
        res = @parseSSFile(files[i])
        @classes = @classes.concat(res.classes)
        @ids = @ids.concat(res.ids)
      defered.resolve()
      console.log @classes, @ids


  getSSFiles: (prjPath) ->
    options =
      followLinks: false

    files = []
    walker = walk.walk(prjPath[0], options)
    defered = Q.defer()
    walker.on 'names', (root, nodeNamesArray)->
      path.normalize(root);
      # console.log('nodes', nodeNamesArray)
      exp = /\w+\.(css|less)$/
      nodeNamesArray.forEach (filename)->
        if exp.test(filename)
          # console.log(root, filename)
          files.push(path.join(path.normalize(root), filename))

    walker.on 'end', ()->
      console.log('total', files);
      defered.resolve(files)

    return defered.promise

  removeFileSelectors: (file)->
    _.remove @classes, (elem)->
      elem.file == file

  parseSSFile: (file)->
    @removeFileSelectors(file)
    buf = fs.readFileSync file, encoding: 'Utf-8';
    try
      cssAST = parse(buf, silent: false);
    catch ex
      console.log 'failed to parse #{file}', ex
      return classes: [], ids: []

    selectors = [];
    for i  in [0...cssAST.stylesheet.rules.length]
      selectors.push
        sel: cssAST.stylesheet.rules[i].selectors[0],
        pos: cssAST.stylesheet.rules[i].position

    # console.log selectors;
    classMatcher = 	/\.([\w|-]*)/gmi
    idMatcher = /#([\w|-]*)/gmi
    classes = [];
    ids = [];

    for i  in [0...selectors.length]
      cls = selectors[i].sel.match(classMatcher)
      for j in [0...cls?.length]
        temp = cls[j].substring(1);
        pos = _.findIndex(classes, name: temp)
        if (pos == -1)
          classes.push
            name: temp,
            file: file,
            positions: [selectors[i].pos]
        else
          classes[pos].positions.push(selectors[i].pos)

      ident = selectors[i].sel.match(idMatcher)
      for j in [0...ident?.length]
        temp = ident[j].substring(1)
        pos = _.findIndex(ids, name: temp)
        if (pos == -1)
          ids.push
            name: temp,
            file: file,
            positions: [selectors[i].pos]
        else
          ids[pos].positions.push(selectors[i].pos)


    return classes: classes, ids: ids

module.exports = SSParser
