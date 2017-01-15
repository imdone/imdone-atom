module.exports = function($) {

  $.expr[':'].attrContainsRegex = function(elem, index, match) {
    try {
      var matchParams = match[3].split(','),
          validLabels = /^(data|css):/,
          attr = {
              method: matchParams[0].match(validLabels) ?
                          matchParams[0].split(':')[0] : 'attr',
              property: matchParams.shift().replace(validLabels,'')
          },
          regexFlags = 'ig',
          regex = new RegExp(matchParams.join('').replace(/^\s+|\s+$/g,''), regexFlags);
      return regex.test($(elem)[attr.method](attr.property));
    } catch(e) {
      return false;
    }
  };

  $.expr[':'].containsRegex = function(elem, index, match) {
    try {
      var regexText = match[3];
      var regex = new RegExp(regexText, 'ig');
      return regex.test($(elem).text());
    } catch(e) {
      return false;
    }
  };
};
