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

String.prototype.hashCode = ->
  hash = 0
  return hash if this.length == 0
  for i in [0...this.length]
      char = this.charCodeAt i
      hash = ((hash<<5)-hash)+char
      hash = hash & hash
  hash


chiavi = [1623324988, 1081239615, 95012445, 877169473, 3505988]

###
      CHEAT LOGIC
###

DL = "DL"
TL = "TL"
DW = "DW"
TW = "TW"

values = {}
values["it"] = { a : 1, b : 5, c : 2, d : 5, e : 1, f : 5, g : 8, h : 8, i : 1, l : 3, m : 3, n : 3, o : 1, p : 5, q : 8, r : 2, s : 2, t : 2, u : 3, v : 5, z : 8 }

window.bloom = {}
bloom.ready = false
bloom.test = (w) ->
  if w.length == 14
    return [false, bloom.words.test w]
  else if w.length in [ 2, 3, 4, 6, 8, 10, 12 ]
    if !bloom[w.length].test w then return [false, false] else return [true, bloom.words.test w]
  [true, bloom.words.test w]

grid = []
multipliers = {}
results = {}

vicini = (pos) ->
  [x, y] = [pos % 4, Math.floor pos / 4]
  res = []
  for oy in [-1..1]
    for ox in [-1..1]
      if (0 <= x-ox <= 3) and (0 <= y-oy <= 3) and (x-ox != 0 or y-oy != 0)
        res.push (x-ox) + (y-oy) * 4
  res

workers = 0
walk = () ->
  for pos in [0...16]
      _.defer discover, pos
      workers += 1

calc_points = (word, path) ->
  res = 0
  for n in [0...word.length]
    res += values["it"][word.charAt n]
  mul = 1
  for own pos, type of multipliers
    if path.split(' ').indexOf(pos) != -1
      res += values["it"][grid[pos].toLowerCase()] if type == DL
      res += 2 * values["it"][grid[pos].toLowerCase()] if type == TL
      mul *= 2 if type == DW
      mul *= 3 if type == TW
  res *= mul
  res += if word.length > 4 then (word.length - 4) * 5 else 0
  res

found = (word, path) ->
  p = calc_points(word, path)
  if !results[word]? or results[word].points < p
    results[word] = { points: p, path: path }

done = ->
  sorted = ([o.points, o.path, word] for word, o of results)
  sorted = _.sortBy(sorted, (x) -> x[0])
  sorted.reverse()
  populate_wordslist sorted
  $("html").removeClass("state-ready").addClass("state-playing")
  next()

discover = (pos, len=0, word='', path='') ->
  len++
  path += " #{pos}"
  word += grid[pos].toLowerCase()
  [go, is_word] = bloom.test word
  found word, path.trim() if is_word
  if go
    for v_pos in vicini pos
      if path.split(' ').indexOf("#{v_pos}") == -1
        discover v_pos, len, word, path
  workers -= 1 if len == 1
  done() if workers == 0

draw_path = (path) ->
  cell_width = $(".grid td").width()
  cell_spacing = parseInt $(".grid").css("border-spacing"), 10
  jump = cell_width + cell_spacing + 2 # border * 2
  start = cell_width / 2 + cell_spacing + 1 # border

  ctx = $(".grid-container > canvas")[0].getContext('2d')
  ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height);

  first = true
  for path_i in path
    path_i = parseInt path_i, 10
    path_x = path_i % 4
    path_y = Math.floor path_i / 4
    if first
      first = false

      ctx.globalAlpha = 0.7

      ctx.beginPath()
      ctx.arc(jump * path_x + start, jump * path_y + start, 10, 0, 2 * Math.PI, false)
      ctx.fillStyle = 'red'
      ctx.fill()

      ctx.lineWidth = 15
      ctx.lineCap = 'round'
      ctx.lineJoin = 'bevel'
      ctx.strokeStyle = 'red'

      ctx.moveTo(jump * path_x + start, jump * path_y + start)
    else
      ctx.lineTo(jump * path_x + start, jump * path_y + start)

  ctx.stroke()

jQuery.get "data/it.bloom", (data) ->
  bloom_data = data.split ";"
  i = 0
  bloom[n] = fromBytestream b64_de bloom_data[i++] for n in [2, 3, 4, 6, 8, 10, 12]
  bloom.words = fromBytestream b64_de bloom_data[i++]
  bloom.ready = true
, "text"


###
      FRONTEND STUFF
###

dom_grid = []
multiplier_state = null
current_word = null
original_font_size = ''

reset = ->
  $(".words-list ul").html ''
  $("html").removeClass("state-playing").addClass("state-ready")
  current_word = null
  for cell in dom_grid
    $(cell).val('')
    $(cell).attr "data-multiplier", ""
  multipliers = {}
  multiplier_state = null
  grid = []
  results = {}
  $(".walk").prop('disabled', yes)
  original_font_size = $('.current-word').css('font-size')

populate_wordslist = (words) ->
  for [points, path, word] in words[0..50]
    $(".words-list ul").append("""<li data-path="#{path}">
                                    <span class="word">#{word}</span>
                                    <span class="points">#{points}</span>
                                  </li>""")

next = ->
  if current_word?
    $(".words-list li").eq(current_word).toggleClass "active"
    # for path_class in $(".words-list li").eq(current_word).attr('data-path-class').split(' ')
    #   $(".grid").toggleClass path_class
    current_word += 1
  else
    current_word = 0
  $(".words-list li").eq(current_word).toggleClass "active"
  $(".current-word").text $(".words-list li > span.word").eq(current_word).text()
  $('.current-word').css('font-size', original_font_size)
  while $(".current-word").width() > 400 # TODO
    $('.current-word').css('font-size', parseInt($('.current-word').css('font-size'), 10) - 1 + 'px')
  $(".current-points").text $(".words-list li > span.points").eq(current_word).text()
  # for path_class in $(".words-list li").eq(current_word).attr('data-path-class').split(' ')
  #   $(".grid").toggleClass path_class
  draw_path $(".words-list li").eq(current_word).attr('data-path').split(' ')
  if current_word > 2
    $(".words-list").scrollTop(46 * (current_word - 2))


bad = ->
  console.log $(".words-list li > span.word").eq(current_word).text()
  $.ajax({ url: "http://ruzzle-map.herokuapp.com/bad", data: { word: $(".words-list li > span.word").eq(current_word).text() }, dataType: 'jsonp', jsonp: 'jsoncall' })
  next()

go = ->
  if not check_grid() then return
  if not bloom.ready then return
  $('textarea').blur()
  walk()

check_grid = ->
  if (_.all [0...16], (x) -> grid[x] of values["it"])
    $(".walk").prop('disabled', no)
    true
  else
    $(".walk").prop('disabled', yes)
    false


jQuery(document).ready ->
  reset()

  $(".grid textarea").each (i) ->
    dom_grid[i] = this
    $(this).attr "data-grid-i", i

  $(".grid textarea").keypress (e) ->
    i = parseInt $(this).attr("data-grid-i"), 10
    if i < 15
      $(dom_grid[i+1]).focus()
    grid[i] = $(this).val() or String.fromCharCode e.which
    check_grid()
    true

  multiplier_numbers =
    48: ''
    49: DL
    50: TL
    51: DW
    52: TW
  $(".grid textarea").keydown (e) ->
    i = parseInt $(this).attr("data-grid-i"), 10
    if e.keyCode == 8
      grid[i] = ''
      check_grid()
      e.stopPropagation()
      if !$(this).val() and i > 0
        $(dom_grid[i-1]).focus()
    if e.keyCode of multiplier_numbers
      multipliers[i] = multiplier_numbers[e.keyCode]
      $(this).attr "data-multiplier", multiplier_numbers[e.keyCode]
      e.stopPropagation()
      false

  $(".multipliers td").click ->
    multiplier_state = $(this).attr "data-multiplier"
    $(".grid textarea").css "cursor", "pointer"

  $(".grid textarea").bind 'focus click dblclick', (e) ->
    if multiplier_state?
      $(".grid textarea").css "cursor", "auto"
      multipliers[parseInt $(this).attr("data-grid-i"), 10] = multiplier_state
      $(this).attr "data-multiplier", multiplier_state
      multiplier_state = null
      $(this).blur()

  $(".walk").click go
  $(".clear").click reset
  $(document).keydown (e) ->
    if e.keyCode == 13 and !current_word?
      go()
      false

  $(".good-button").click next
  $(document).keydown (e) ->
    if e.keyCode == 32 and current_word?
      next()
      false
  $(".bad-button").click bad
  $(document).keydown (e) ->
    if e.keyCode == 8 and current_word?
      bad()
      false

  grid_size = $(".grid-container").width()
  canvas = $(".grid-container > canvas")
  canvas.css('width', grid_size + 'px').css('height', grid_size + 'px')
  canvas.attr('width', grid_size).attr('height', grid_size)

  if not $.cookie("chiave") or Math.abs($.cookie("chiave").toLowerCase().hashCode()) not in chiavi
    $("html").addClass("state-beta")
  $(".beta-box input").keyup ->
    console.log Math.abs($(this).val().toLowerCase().hashCode())
    if Math.abs($(this).val().toLowerCase().hashCode()) in chiavi
      $(this).blur()
      $('html').removeClass 'state-beta'
      $.cookie("chiave", $(this).val())
  $(".beta-box input").focus()
