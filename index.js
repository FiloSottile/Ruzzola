// Generated by CoffeeScript 1.4.0
(function() {
  var b64_de,
    __hasProp = {}.hasOwnProperty;

  require.config({
    paths: {
      "jquery": "//cdnjs.cloudflare.com/ajax/libs/jquery/1.8.3/jquery.min",
      "underscore": "//cdnjs.cloudflare.com/ajax/libs/underscore.js/1.4.3/underscore-min"
    }
  });

  b64_de = function(data) {
    var b64, bits, h1, h2, h3, h4, i, o1, o2, o3, res;
    b64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
    res = [];
    i = 0;
    while (i < data.length) {
      h1 = b64.indexOf(data.charAt(i++));
      h2 = b64.indexOf(data.charAt(i++));
      h3 = b64.indexOf(data.charAt(i++));
      h4 = b64.indexOf(data.charAt(i++));
      bits = h1 << 18 | h2 << 12 | h3 << 6 | h4;
      o1 = bits >> 16 & 0xff;
      o2 = bits >> 8 & 0xff;
      o3 = bits & 0xff;
      if (h3 === 64) {
        res.push(o1);
      } else if (h4 === 64) {
        res.push(o1, o2);
      } else {
        res.push(o1, o2, o3);
      }
    }
    return res;
  };

  require(["bloomfilter", "jquery", "underscore"], function(bloomfilter, $) {
    /*
            CHEAT LOGIC
    */

    var DL, DW, TL, TW, bad, calc_points, current_word, discover, dom_grid, done, draw_path, found, grid, multiplier_state, multipliers, next, populate_wordslist, reset, results, values, vicini, walk, workers;
    DL = "DL";
    TL = "TL";
    DW = "DW";
    TW = "TW";
    values = {};
    values["it"] = {
      a: 1,
      b: 5,
      c: 2,
      d: 5,
      e: 1,
      f: 5,
      g: 8,
      h: 8,
      i: 1,
      l: 3,
      m: 3,
      n: 3,
      o: 1,
      p: 5,
      q: 8,
      r: 2,
      s: 2,
      t: 2,
      u: 3,
      v: 5,
      z: 8
    };
    window.bloom = {};
    bloom.ready = false;
    bloom.test = function(w) {
      var _ref;
      if (w.length === 14) {
        return [false, bloom.words.test(w)];
      } else if ((_ref = w.length) === 2 || _ref === 3 || _ref === 4 || _ref === 6 || _ref === 8 || _ref === 10 || _ref === 12) {
        if (!bloom[w.length].test(w)) {
          return [false, false];
        } else {
          return [true, bloom.words.test(w)];
        }
      }
      return [true, bloom.words.test(w)];
    };
    grid = [];
    multipliers = {};
    results = {};
    vicini = function(pos) {
      var ox, oy, res, x, y, _i, _j, _ref, _ref1, _ref2;
      _ref = [pos % 4, Math.floor(pos / 4)], x = _ref[0], y = _ref[1];
      res = [];
      for (oy = _i = -1; _i <= 1; oy = ++_i) {
        for (ox = _j = -1; _j <= 1; ox = ++_j) {
          if (((0 <= (_ref1 = x - ox) && _ref1 <= 3)) && ((0 <= (_ref2 = y - oy) && _ref2 <= 3)) && (x - ox !== 0 || y - oy !== 0)) {
            res.push((x - ox) + (y - oy) * 4);
          }
        }
      }
      return res;
    };
    workers = 0;
    walk = function() {
      var pos, _i, _results;
      _results = [];
      for (pos = _i = 0; _i < 16; pos = ++_i) {
        _.defer(discover, pos);
        _results.push(workers += 1);
      }
      return _results;
    };
    calc_points = function(word, path) {
      var mul, n, pos, res, type, _i, _ref;
      res = 0;
      for (n = _i = 0, _ref = word.length; 0 <= _ref ? _i < _ref : _i > _ref; n = 0 <= _ref ? ++_i : --_i) {
        res += values["it"][word.charAt(n)];
      }
      mul = 1;
      for (pos in multipliers) {
        if (!__hasProp.call(multipliers, pos)) continue;
        type = multipliers[pos];
        if (path.split(' ').indexOf(pos) !== -1) {
          if (type === DL) {
            res += values["it"][grid[pos]];
          }
          if (type === TL) {
            res += 2 * values["it"][grid[pos]];
          }
          if (type === DW) {
            mul *= 2;
          }
          if (type === TW) {
            mul *= 3;
          }
        }
      }
      res *= mul;
      res += word.length > 4 ? (word.length - 4) * 5 : 0;
      return res;
    };
    found = function(word, path) {
      var p;
      p = calc_points(word, path);
      if (!(results[word] != null) || results[word].points < p) {
        return results[word] = {
          points: p,
          path: path
        };
      }
    };
    done = function() {
      var o, sorted, word;
      sorted = (function() {
        var _results;
        _results = [];
        for (word in results) {
          o = results[word];
          _results.push([o.points, o.path, word]);
        }
        return _results;
      })();
      sorted = _.sortBy(sorted, function(x) {
        return x[0];
      });
      sorted.reverse();
      populate_wordslist(sorted);
      $(".grid-container > canvas").show();
      return next();
    };
    discover = function(pos, len, word, path) {
      var go, is_word, v_pos, _i, _len, _ref, _ref1;
      if (len == null) {
        len = 0;
      }
      if (word == null) {
        word = '';
      }
      if (path == null) {
        path = '';
      }
      len++;
      path += " " + pos;
      word += grid[pos];
      _ref = bloom.test(word), go = _ref[0], is_word = _ref[1];
      if (is_word) {
        found(word, path.trim());
      }
      if (go) {
        _ref1 = vicini(pos);
        for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
          v_pos = _ref1[_i];
          if (path.split(' ').indexOf("" + v_pos) === -1) {
            discover(v_pos, len, word, path);
          }
        }
      }
      if (len === 1) {
        workers -= 1;
      }
      if (workers === 0) {
        return done();
      }
    };
    draw_path = function(path) {
      var ctx, first, path_i, path_x, path_y, _i, _len;
      ctx = $(".grid-container > canvas")[0].getContext('2d');
      ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height);
      first = true;
      for (_i = 0, _len = path.length; _i < _len; _i++) {
        path_i = path[_i];
        path_i = parseInt(path_i, 10);
        path_x = path_i % 4;
        path_y = Math.floor(path_i / 4);
        if (first) {
          first = false;
          ctx.globalAlpha = 0.7;
          ctx.beginPath();
          ctx.arc(54 * path_x + 28, 54 * path_y + 28, 10, 0, 2 * Math.PI, false);
          ctx.fillStyle = 'red';
          ctx.fill();
          ctx.lineWidth = 15;
          ctx.lineCap = 'round';
          ctx.lineJoin = 'bevel';
          ctx.strokeStyle = 'red';
          ctx.moveTo(54 * path_x + 28, 54 * path_y + 28);
        } else {
          ctx.lineTo(54 * path_x + 28, 54 * path_y + 28);
        }
      }
      ctx.stroke();
      return $(ctx.canvas).show();
    };
    jQuery.get("data/it.bloom", function(data) {
      var bloom_data, i, n, _i, _len, _ref;
      bloom_data = data.split(";");
      i = 0;
      _ref = [2, 3, 4, 6, 8, 10, 12];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        n = _ref[_i];
        bloom[n] = bloomfilter.fromBytestream(b64_de(bloom_data[i++]));
      }
      bloom.words = bloomfilter.fromBytestream(b64_de(bloom_data[i++]));
      return bloom.ready = true;
    }, "text");
    /*
            FRONTEND STUFF
    */

    dom_grid = [];
    multiplier_state = null;
    current_word = null;
    reset = function() {
      var cell, _i, _len;
      $(".words-list ul").html('');
      $(".good-button, .bad-button, .current-word").hide();
      $(".grid-container > canvas").hide();
      current_word = null;
      for (_i = 0, _len = dom_grid.length; _i < _len; _i++) {
        cell = dom_grid[_i];
        $(cell).val('');
        $(cell).attr("data-multiplier", "");
      }
      multipliers = {};
      dom_grid = [];
      multiplier_state = null;
      grid = [];
      multipliers = {};
      return results = {};
    };
    populate_wordslist = function(words) {
      var path, points, word, _i, _len, _ref, _ref1, _results;
      _ref = words.slice(0, 51);
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        _ref1 = _ref[_i], points = _ref1[0], path = _ref1[1], word = _ref1[2];
        _results.push($(".words-list ul").append("<li data-path=\"" + path + "\">\n  <span class=\"word\">" + word + "</span>\n  <span class=\"points\">" + points + "</span>\n</li>"));
      }
      return _results;
    };
    next = function() {
      if (current_word != null) {
        $(".words-list li").eq(current_word).toggleClass("active");
        current_word += 1;
      } else {
        $(".good-button, .bad-button, .current-word").show();
        current_word = 0;
      }
      $(".words-list li").eq(current_word).toggleClass("active");
      $(".current-word").text($(".words-list li > span.word").eq(current_word).text());
      return draw_path($(".words-list li").eq(current_word).attr('data-path').split(' '));
    };
    bad = function() {
      console.log($(".words-list li > span.word").eq(current_word).text());
      $.ajax({
        url: "http://ruzzle-map.herokuapp.com/bad",
        data: {
          word: $(".words-list li > span.word").eq(current_word).text()
        },
        dataType: 'jsonp',
        jsonp: 'jsoncall'
      });
      return next();
    };
    return jQuery(document).ready(function() {
      var canvas, grid_size, multiplier_numbers;
      reset();
      $(".grid textarea").each(function(i) {
        dom_grid[i] = this;
        return $(this).attr("data-grid-i", i);
      });
      $(".grid textarea").keypress(function(e) {
        var i;
        i = parseInt($(this).attr("data-grid-i"), 10);
        if (i < 15) {
          $(dom_grid[i + 1]).focus();
        }
        return grid[i] = $(this).val() || String.fromCharCode(e.which);
      });
      multiplier_numbers = {
        49: DL,
        50: TL,
        51: DW,
        52: TW
      };
      $(".grid textarea").keydown(function(e) {
        var i;
        i = parseInt($(this).attr("data-grid-i"), 10);
        if (e.keyCode === 8) {
          e.stopPropagation();
          if (!$(this).val() && i > 0) {
            $(dom_grid[i - 1]).focus();
          }
        }
        if (e.keyCode in multiplier_numbers) {
          multipliers[i] = multiplier_numbers[e.keyCode];
          $(this).attr("data-multiplier", multiplier_numbers[e.keyCode]);
          e.stopPropagation();
          return false;
        }
      });
      $(".multipliers td").click(function() {
        multiplier_state = $(this).attr("data-multiplier");
        return $(".grid textarea").css("cursor", "pointer");
      });
      $(".grid textarea").bind('focus click dblclick', function(e) {
        if (multiplier_state != null) {
          $(".grid textarea").css("cursor", "auto");
          multipliers[parseInt($(this).attr("data-grid-i"), 10)] = multiplier_state;
          $(this).attr("data-multiplier", multiplier_state);
          multiplier_state = null;
          return $(this).blur();
        }
      });
      $(".walk").click(walk);
      $(".clear").click(reset);
      $(".good-button").click(next);
      $(document).keydown(function(e) {
        if (e.keyCode === 32 && (current_word != null)) {
          next();
          return false;
        }
      });
      $(".bad-button").click(bad);
      $(document).keydown(function(e) {
        if (e.keyCode === 8 && (current_word != null)) {
          bad();
          return false;
        }
      });
      grid_size = $(".grid-container").width();
      canvas = $(".grid-container > canvas");
      canvas.css('width', grid_size + 'px').css('height', grid_size + 'px');
      return canvas.attr('width', grid_size).attr('height', grid_size);
    });
  });

}).call(this);
