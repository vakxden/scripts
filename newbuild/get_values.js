function getParamsFromFile(filename) {
  var params = {};
  var contents = grunt.file.read(filename); // TODO: error handling
  var lines = contents.split(/\r?\n/);
  lines.forEach(function(l) {
    var index = l.indexOf('=');
    if (index === -1) {
      return;
    }
    var key = l.slice(0, index);
    var value = l.slice(index + 1);
    params[key] = value;
  });
  return params;
}
file = "/home/dvac/git/scripts/newbuild/meta-ocean-deploy"
getParamsFromFile(file)
