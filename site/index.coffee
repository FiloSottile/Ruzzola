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

grid = [['a', 'c', 'a', 'c'],
        ['a', 'c', 'e', 'b'],
        ['a', 's', 't', 'b'],
        ['a', 'c', 'a', 'b']]

vicini = (x, y) ->
  res = []
  for oy in [-1..1]
    for ox in [-1..1]
      if (0 <= x-ox <= 3) and (0 <= y-oy <= 3) and (x-ox != 0 or y-oy != 0)
        res.push [x-ox, y-oy]
  res

walk = ->
  for walk_x in [0..3]
    for walk_y in [0..3]
      discover walk_x, walk_y

found = (word, path) ->
  # TODO
  console.log word, path

discover = (x, y, len=0, word='', path='') ->
  len++
  path += " - #{x}##{y}"
  word += grid[y][x]
  [go, is_word] = bloom.test word
  found word, path if is_word
  if go
    for [vx, vy] in vicini x, y
      if path.split(' - ').indexOf("#{vx}##{vy}") == -1
        discover vx, vy, len, word, path

require ["jquery", "underscore", "bloomfilter"], ($, _, bloomfilter) ->
  jQuery.get "/data/it.bloom", (data) ->
    bloom_data = data.split ";"
    bloom_filters = window.bloom
    i = 0
    bloom_filters[n] = bloomfilter.fromBytestream b64_de bloom_data[i++] for n in [2..19]
    bloom_filters.words = bloomfilter.fromBytestream b64_de bloom_data[i]
    bloom_filters.ready = true
    window.bloom = bloom_filters
  , "text"
