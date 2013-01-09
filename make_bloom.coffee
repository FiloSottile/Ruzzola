bloomfilter = require "./bloomfilter.js/bloomfilter.js"
fs = require "fs"

elements = []

process.stdin.resume()
process.stdin.setEncoding 'utf8'
process.stdin.on 'data', (chunk) ->
  elements = elements.concat chunk.trim().split('\n')

process.stdin.on 'end', ->
  n = elements.length
  p = 0.0001
  m = Math.ceil((n * Math.log(p)) / Math.log(1.0 / (Math.pow(2.0, Math.log(2.0)))))
  k = Math.round(Math.log(2.0) * m / n)
  bloom = new bloomfilter.BloomFilter m, k
  process.stderr.write "#{n}, #{p}, #{m}, #{k}\n"

  for word in elements
    bloom.add word.trim().toLowerCase().replace(/[^a-z]/, '')

  process.stdout.write Buffer(bloom.toBytestream()).toString('base64')
