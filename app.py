import web
import os
import urllib2
from pymongo import MongoClient
import datetime

DEBUG = (os.environ.get('DEBUG') == '1')
connection = MongoClient(os.environ['MONGOLAB_URI'])
db = connection.heroku_app10932334

urls = (
    '/bad', 'bad',
)

class bad:
    def GET(self):
        word = web.input().get('word')
        if not word:
            raise web.forbidden()

        web.header('Access-Control-Allow-Origin', '*')

        bad_word = { 'word': word,
                     'ip': web.ctx.ip,
                     'time': datetime.datetime.utcnow() }
        return db.bad.insert(bad_word)


application = web.application(urls, globals())
if DEBUG: application.internalerror = web.debugerror
app = application.wsgifunc()
