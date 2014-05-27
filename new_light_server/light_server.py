#!/usr/local/bin/python2.7
#
# Light Server, to replace the connectport
#
from xbee import ZigBee
from serial import Serial
from flask import Flask
from flask import render_template
from flask import jsonify
from flask import request,redirect,url_for
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
nodes = {}
xbee = None
localnodeH = None
localnodeL = None
expr = re.compile('Qr(\d+)g(\d+)b(\d+)s(\d+)\r\n.*r(\d+)g(\d+)b(\d+)\r\n', re.M)

def sendToNode(node,data,frame_id='A'):
    logger.debug("sending %s to %s", data, node['string_address'])
    xbee.send("tx", dest_addr_long=node['address'], dest_addr='\xff\xfe', data=data, frame_id=frame_id)

def atToNode(node,command,parameter,frame_id='B'):
    logger.debug("sending %s %s to %s", command, parameter, node['string_address'])
    xbee.remote_at(command=command, parameter=parameter, dest_addr_long=node['address'], frame_id=frame_id)
    
@app.route('/lights')
def lights():
    logger.debug(request.args.to_dict())
    for nodekey in nodes.keys():
        node = nodes[nodekey]
        key=node['name']+"_color"
        if key in request.args:
            # this can probably be done more simply
            newcolor = struct.unpack('4B',struct.pack('>L',int(request.args[key],16)))[1:]
            if ('color' not in node and sum(newcolor) > 0) or ('color' in node and node['color'] != newcolor):
                node['color'] = newcolor
                node['colorvalue'] = request.args[key]
                sendToNode(node,'r{0}g{1}b{2}\n'.format(newcolor[0],newcolor[1],newcolor[2]))
    return render_template('lights.html',nodes=nodes)

@app.route('/')
def index():
    return redirect(url_for('lights'))

@app.route('/query')
def query():
    retnodes=[]
    for key in nodes.keys():
        node = nodes[key]
        retnode = {'address': node['string_address'], 'name': node['name']}
        if 'color' in node:
            retnode['color'] = '{0[0]:02x}{0[1]:02x}{0[2]:02x}'.format(node['color'])
        retnodes.append(retnode)
    return jsonify(nodes=retnodes)

def add_node(data): 
    logger.debug('%s',data)
    if data['id'] == 'at_response' and data['command'] == 'ND':
        key = '{0:08x}'.format(struct.unpack('>Q',data['parameter']['source_addr_long'])[0])
        if key not in nodes:
            nodes[key] = ({'address': data['parameter']['source_addr_long'], 'string_address': key, 'name': data['parameter']['node_identifier'], 'colorvalue': '000000'})
    elif data['id'] == 'at_response' and data['command'] == 'SH':
        localnodeH = data['parameter']
    elif data['id'] == 'at_response' and data['command'] == 'SL':
        localnodeL = data['parameter']
    elif data['id'] == 'rx':
        parse_query_response(data['source_addr_long'], data['rf_data'])

def parse_query_response(source_addr, data):
    if data[0] != 'Q': return
    if source_addr not in nodes: return
    m = expr.match(data)
    if not m: return
    g = map(int, m.groups())
    node = nodes[source_addr]
    node['color'] = g[0:3]
    node['color2'] = g[4:7]
    node['speed'] = g[3]
    logger.debug(node)

def do_queries():
    time.sleep(5)
    while True:
        if localnodeH and localnodeL:
            for key in nodes.keys():
                node = nodes[key]
                logger.debug("Querying %s", node['string_address'])
                atToNode(node,'DH',localnodeH);
                atToNode(node,'DL',localnodeL);
                sendToNode(node,'AQ')
        time.sleep(30)

def start_callback(xbee):
    print "starting"

if __name__ == '__main__':
    serial_port = Serial('/dev/tty.usbserial-A901LVJC', 9600)
    xbee = ZigBee(serial_port, callback=add_node, start_callback=start_callback)
    xbee.start()
    xbee.send("at",command='ND',frame_id='1')
    xbee.send("at",command='SH',frame_id='2')
    xbee.send("at",command='SL',frame_id='2')
    queryThread = threading.Thread(target=do_queries)
    queryThread.daemon = True
    queryThread.start()
    app.run(host='0.0.0.0')
