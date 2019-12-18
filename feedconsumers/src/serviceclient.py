import urllib3

import json
import urllib3
import certifi
try:
    from urllib import urlencode
except ImportError:
    from urllib.parse import urlencode


class APIClient(object):
    BASE_URL = 'http://localhost:5000/'

    def __init__(self, rate_limit_lock=None, encoding='utf8'):
        self.rate_limit_lock = rate_limit_lock
        self.encoding = encoding
        self.connection_pool = self._make_connection_pool()

    def _make_connection_pool(self):
        return urllib3.PoolManager( cert_reqs='CERT_REQUIRED',
                                    ca_certs=certifi.where())

    def _compose_url(self, path, params=None):
        url = self.BASE_URL
        if path:
            url += path
        if params:
            url += '?' + urlencode(params) 
        return url

    def _handle_response(self, response):
        print(response, response.data)
        return json.loads(response.data.decode(self.encoding))

    def _request(self, method, path, params=None, data=None):
        url = self._compose_url(path, params)

        self.rate_limit_lock and self.rate_limit_lock.acquire()
        if data:
            r = self.connection_pool.request(method.upper(), url, data)
        else:
            r = self.connection_pool.request(method.upper(), url)

        return self._handle_response(r)

    def post(self, path, data):
        return self._request('POST', path, params=None, data=data)

    def get(self, path, **params):
        return self._request('GET', path, params=params, data=None)

class TaxiCounts(APIClient):
    def __init__(self, url='http://127.0.0.1:8000/'):
        super(TaxiCounts, self).__init__()
        self.BASE_URL = url

    def add_counts(self, counts):
        r = self.post('/add_counts', {"counts": str(counts)})
        if r['status'] == 0:
            print("Saved: ", counts)
            return True
        else:
            print("Failed to Save: ", counts)
            return False

    def get_count(self):
        return self.get('/').get("counts", None)

def main(url):
    t = TaxiCounts(url)
    print("add_counts: 100", t.add_counts(100))
    r = t.get_count()
    print("get_count: ", r, type(r))

def tail_counts(url="http://taxiservice-main:80"):
    import time
    t = TaxiCounts(url)
    while True:
        r = t.get_count()
        print("get_count: ", r, type(r))    
        time.sleep(1)
if __name__ == '__main__':
    import sys
    if len(sys.argv) > 1:
        tail_counts(sys.argv[1])
    else:
        tail_counts()
