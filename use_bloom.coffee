bloomfilter = require "./bloomfilter.js/bloomfilter.js"
fs = require "fs"

Buffer.prototype.toByteArray = ->
  Array.prototype.slice.call(this, 0)

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

filename = process.argv[2]

bloom = false
fs.readFile filename, (err, data) ->
  throw err if err
  #bloom = bloomfilter.fromBytestream data.toByteArray()
  bloom = bloomfilter.fromBytestream b64_de data.toString('ascii')

process.stdin.resume()
process.stdin.setEncoding 'utf8'
process.stdin.on 'data', (chunk) ->
  return if !bloom
  console.log bloom.test chunk.trim()
