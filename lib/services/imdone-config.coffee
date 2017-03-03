
pkg = require '../../package.json'

module.exports =
  getPackageName: () -> pkg.name

  getPackagePath: () -> atom.packages.getLoadedPackage(pkg.name).path

  getSettings: () ->
    return {} unless atom && atom.config
    atom.config.get "#{pkg.name}" || {}
