bloomfilter = require "./bloomfilter.js/bloomfilter.js"
fs = require "fs"

filename = process.argv[2]
[ m, k ] = ( parseInt(x, 10) for x in process.argv[3..]  )
# TODO calculate m, k

bloom = new bloomfilter.BloomFilter m, k

process.stdin.resume()
process.stdin.setEncoding 'utf8'
process.stdin.on 'data', (chunk) ->
  for word in chunk.trim().split('\n')
    bloom.add word

process.stdin.on 'end', ->
  #fs.writeFile filename, Buffer bloom.toBytestream()
  fs.writeFile filename, Buffer(bloom.toBytestream()).toString('base64')
