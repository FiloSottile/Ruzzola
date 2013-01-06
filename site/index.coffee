require.config {
  paths: {
    "jquery": "//cdnjs.cloudflare.com/ajax/libs/jquery/1.8.3/jquery.min",
    "underscore": "//cdnjs.cloudflare.com/ajax/libs/underscore.js/1.4.3/underscore-min",
  }
}

b64_de = (data) ->
  b64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
  res = []
  i = 0
  while i < data.length
    h1 = b64.indexOf(data.charAt(i++))
    h2 = b64.indexOf(data.charAt(i++))
    h3 = b64.indexOf(data.charAt(i++))
    h4 = b64.indexOf(data.charAt(i++))

    bits = h1 << 18 | h2 << 12 | h3 << 6 | h4;

    o1 = bits >> 16 & 0xff;
    o2 = bits >> 8 & 0xff;
    o3 = bits & 0xff;

    if h3 == 64
      res.push(o1)
    else if h4 == 64
      res.push(o1, o2)
    else
      res.push(o1, o2, o3)
  res

DL = 1
TL = 2
DW = 3
TW = 4

require ["bloomfilter", "jquery", "underscore"], (bloomfilter, $) ->

  values = {}
  values["it"] = $.parseJSON '{ "a" : 1, "b" : 5, "c" : 2, "d" : 5, "e" : 1, "f" : 5,
                   "g" : 8, "h" : 8, "i" : 1, "l" : 3, "m" : 3, "n" : 3,
                   "o" : 1, "p" : 5, "q": 100, "r" : 2, "s" : 2, "t" : 2,
                   "u" : 3, "v" : 5, "z" : 8 }'

  window.bloom = {}
  window.bloom.ready = false
  window.bloom.test = (w) ->
    if w.length == 20
      return [false, window.bloom.words.test w]
    if w.length == 1
      return [true, false]
    if !window.bloom[w.length].test w
      return [false, false]
    [true, window.bloom.words.test w]

  grid = ['r', 'n', 'o', 'r',
          't', 'm', 'e', 'r',
          'r', 'r', 'i', 't',
          'n', 'c', 'a', 'p']

  multipliers = { '2': TW, '3': 'DL', '5': DW, '8': TL, '12': DW }

  vicini = (pos) ->
    [x, y] = [pos % 4, Math.floor pos / 4]
    res = []
    for oy in [-1..1]
      for ox in [-1..1]
        if (0 <= x-ox <= 3) and (0 <= y-oy <= 3) and (x-ox != 0 or y-oy != 0)
          res.push (x-ox) + (y-oy) * 4
    res

  workers = 0
  window.walk = (g) ->
    if g
      grid = g.split ''
    for pos in [0...16]
        _.defer discover, pos
        workers += 1

  window.points = (word, path) ->
    res = 0
    for n in [0...word.length]
      res += values["it"][word.charAt n]
    mul = 1
    for own pos, type of multipliers
      if path.split(' ').indexOf(pos) != -1
        res += values["it"][grid[pos]] if type == DL
        res += 2 * values["it"][grid[pos]] if type == TL
        mul *= 2 if type == DW
        mul *= 3 if type == TW
    res *= mul
    res += if word.length > 4 then (word.length - 4) * 5 else 0
    res

  found = (word, path) ->
    # TODO
    console.log word, path, points(word, path)

  done = ->
    #TODO
    console.log 'done'

  discover = (pos, len=0, word='', path='') ->
    len++
    path += " #{pos}"
    word += grid[pos]
    [go, is_word] = bloom.test word
    found word, path.trim() if is_word
    if go
      for v_pos in vicini pos
        if path.split(' ').indexOf("#{v_pos}") == -1
          discover v_pos, len, word, path
    workers -= 1 if len == 1
    done() if workers == 0

  jQuery.get "/data/it.bloom", (data) ->
    bloom_data = data.split ";"
    bloom_filters = window.bloom
    i = 0
    bloom_filters[n] = bloomfilter.fromBytestream b64_de bloom_data[i++] for n in [2..19]
    bloom_filters.words = bloomfilter.fromBytestream b64_de bloom_data[i++]
    bloom_filters.ready = true
    window.bloom = bloom_filters
  , "text"
