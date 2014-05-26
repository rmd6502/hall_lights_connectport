#!/usr/local/bin/python2.7
#
# Light Server, to replace the connectport
#
from xbee import ZigBee
from serial import Serial
from flask import Flask
from flask import render_template
from flask import jsonify
from flask import request
import struct
import threading
import time
import logging

logger = logging.getLogger()
logger.setLevel(logging.DEBUG)
ch = logging.StreamHandler()
ch.setLevel(logging.DEBUG)
logger.addHandler(ch)

app = Flask(__name__)
nodes = []
xbee = None

@app.route('/')
@app.route('/lights')
def index():
    logger.debug(request.form)
    return render_template('lights.html',nodes=nodes)

@app.route('/query')
def query():
    retnodes=[]
    for node in nodes:
        retnode = {'address': node['string_address'], 'name': node['name']}
        if 'color' in node:
            retnode['color'] = node['color']
        retnodes.append(retnode)
    return jsonify(nodes=retnodes)


def add_node(data): 
    logger.debug('%s',data)
    if data['id'] == 'at_response' and data['command'] == 'ND':
        nodes.append({'address': data['parameter']['source_addr_long'], 'string_address': '{0:08x}'.format(struct.unpack('>Q',data['parameter']['source_addr_long'])[0]), 'name': data['parameter']['node_identifier']})


def do_queries():
    time.sleep(5)
    while True:
        for node in nodes:
            logger.debug("Querying %s", node['string_address'])
            xbee.send("tx", dest_addr_long=node['address'], dest_addr='\xff\xfe', data='AQ', frame_id='2')
        time.sleep(30)

def start_callback(xbee):
    print "starting"

if __name__ == '__main__':
    serial_port = Serial('/dev/tty.usbserial-A901LVJC', 9600)
    xbee = ZigBee(serial_port, callback=add_node, start_callback=start_callback)
    xbee.send("at",command='ND',frame_id='1')
    queryThread = threading.Thread(target=do_queries)
    queryThread.daemon = True
    queryThread.start()
    app.run()
