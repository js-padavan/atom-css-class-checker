fs = require 'fs'
walk = require 'walk'
path = require 'path'
Q = require 'q'
parse = require 'css-parse'
_ = require 'lodash'
{Emitter} = require 'event-kit'

class SSParser

  constructor: ->
    @emitter = new Emitter()
    @classes = []
    @ids = []
    @ssFiles = []
    defered = Q.defer()
    @loaded = defered.promise;

    prjDir = atom.project.getPaths()

    @getSSFiles(prjDir).then (files)=>
      @ssFiles = files
      for i in [0...files.length]
        res = @parseSSFile(files[i])
        @classes = @classes.concat(res.classes)
        @ids = @ids.concat(res.ids)
      defered.resolve()


  getSSFiles: (prjPath) ->
    {ignoreDirectories, ignoreFiles} = atom.config.get('atom-css-class-checker')
    options =
      followLinks: false
      filters: ignoreDirectories

    files = []
    walker = walk.walk(prjPath[0], options)
    defered = Q.defer()
    walker.on 'names', (root, nodeNamesArray)->
      path.normalize(root);
      # console.log('nodes', nodeNamesArray)
      exp = /\w+\.(css)$/
      nodeNamesArray.forEach (filename)->
        if _.indexOf(ignoreFiles, filename) >= 0
          return
        if exp.test(filename)
          # console.log(root, filename)
          files.push(path.join(path.normalize(root), filename))

    walker.on 'end', ()->
      defered.resolve(files)

    return defered.promise

  removeFileSelectors: (file)->
    _.remove @classes, (elem)->
      elem.file == file

  updateWithSSFile: (file, text)->
    return unless file isnt undefined and text isnt undefined
    @removeFileSelectors(file)
    res = @parseText(text, file)
    @classes = @classes.concat(res.classes)
    @ids = @ids.concat(res.ids)
    @emitter.emit('onDidUpdate')


  parseSSFile: (file)->
    buf = fs.readFileSync file, encoding: 'Utf-8';
    @parseText(buf, file)

  parseText: (buf, file)->
    checkIds = atom.config.get('atom-css-class-checker.checkIds')
    try
      cssAST = parse(buf, silent: false);
    catch ex
      console.log 'failed to parse #{file}', ex
      return classes: [], ids: []

    selectors = [];
    for i  in [0...cssAST.stylesheet.rules.length]
      if (cssAST.stylesheet.rules[i].selectors)
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
            references: [pos: selectors[i].pos, sel: selectors[i].sel, file: file]
        else
          classes[pos].references.push
            pos: selectors[i].pos
            sel: selectors[i].sel
            file: file

      if checkIds
        ident = selectors[i].sel.match(idMatcher)
        for j in [0...ident?.length]
          temp = ident[j].substring(1)
          pos = _.findIndex(ids, name: temp)
          if (pos == -1)
            ids.push
              name: temp,
              file: file,
              references: [pos: selectors[i].pos, sel: selectors[i].sel]
          else
            ids[pos].references.push(pos: selectors[i].pos, sel: selectors[i].sel)

    return classes: classes, ids: ids

  onDidUpdate: (cb)->
    @emitter.on('onDidUpdate', cb)

module.exports = SSParser
