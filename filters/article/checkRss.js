// Generated by CoffeeScript 1.9.3
(function() {
  var func_column;

  func_column = __F('column');

  module.exports = function(req, res, next) {
    if (res.locals.user && res.locals.columns) {
      return func_column.getRssesByUserId(res.locals.user.id, function(error, rsses) {
        var rssed_column_ids;
        if (rsses && rsses.length) {
          rssed_column_ids = [];
          rsses.forEach(function(rss) {
            return rssed_column_ids.push(rss.column_id);
          });
          res.locals.columns.forEach(function(column) {
            if (rssed_column_ids.indexOf(column.id) !== -1) {
              return column.is_rssed = true;
            }
          });
          return next();
        } else {
          return next();
        }
      });
    } else {
      return next();
    }
  };

}).call(this);
