from mitmproxy import ctx
from mitmproxy import http
CONTENT_TYPE_FIELD = "content-type"
#javascript_file = 0

def response(flow: http.HTTPFlow):
#    global javascript_file
    if flow.request.method == "GET" and \
        CONTENT_TYPE_FIELD in flow.response.headers:

        content_type = flow.response.headers[CONTENT_TYPE_FIELD]
        path = flow.request.path

        if content_type.find("json") >= 0:
            if path.find("covid/data?ig") >= 0:
                with open('/tmp/covid_data.txt', "w") as f:
                    f.write(flow.response.text)
#         elif content_type.find("javascript") >= 0:
#             javascript_file += 1
#             with open('/tmp/covid_javascript_%s.txt' % javascript_file, "w") as f:
#                 f.write(flow.response.text)

