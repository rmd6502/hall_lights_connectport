#####################################################################
# This is the main project module
# Created on: 24 February 2012
# Author: Robert Diamond
# Description:
#####################################################################

web_template = """
<HEAD>
<TITLE>Light Control</TITLE>
<SCRIPT TYPE="text/javascript">
function setcolor(colordiv) {
    colordiv.style.margin = "";
    colordiv.style.border = "2px; black;";
    document.forms[0].color.value = colordiv.textContent;
    document.forms[0].submit();
}
HTMLElement.prototype.hasFocus = 0;
var lastXML;
function updateInputs() {
    var sel = document.getElementsByName("node")[0];
    var selNode = sel.options[sel.selectedIndex].value;
    var x = lastXML;
    if (x == null) return;
    var lights = x.getElementsByTagName("light");
    for (var lightno=0; lightno < lights.length; ++lightno) {
        var light = lights.item(lightno);
        if (light.attributes.getNamedItem("node").nodeValue == selNode) {
            if (!document.getElementsByName("red")[0].hasFocus) {
                document.getElementsByName("red")[0].value = 
                    light.getElementsByTagName("red")[0].firstChild.nodeValue;
            }
            if (!document.getElementsByName("green")[0].hasFocus) {
                document.getElementsByName("green")[0].value = 
                    light.getElementsByTagName("green")[0].firstChild.nodeValue;
            }
            if (!document.getElementsByName("blue")[0].hasFocus) {
                document.getElementsByName("blue")[0].value = 
                    light.getElementsByTagName("blue")[0].firstChild.nodeValue;
            }
            if (!document.getElementsByName("speed")[0].hasFocus) {
                document.getElementsByName("speed")[0].value = 
                    light.getElementsByTagName("speed")[0].firstChild.nodeValue;
            }
            break;
        }
    }
}
function updateAjax(url) {
    if (window.XMLHttpRequest) {// code for IE7+, Firefox, Chrome, Opera, Safari
        xmlhttp=new XMLHttpRequest();
    } else {// code for IE6, IE5
        xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
    }
    xmlhttp.onreadystatechange=function() {
        if (xmlhttp.readyState==4 && xmlhttp.status==200) {
            lastXML = xmlhttp.responseXML;
            updateInputs();
        }
        if (xmlhttp.readyState == 4) {
            window.setTimeout("updateAjax('"+url+"')", 7000);
        }
    }
    xmlhttp.open("GET",url,true);
    xmlhttp.send();
}
</SCRIPT>
</HEAD>
<BODY onload="updateAjax(location.origin+'/query')">
<FORM METHOD="POST">
<TABLE>
<TR>
<TD>Choose Node</TD><TD><SELECT NAME="node" onchange="updateInputs()">
%(nodes)s
</SELECT></TD>
</TR>
<TR>
<TD>Red</TD>
<TD><INPUT TYPE="text" NAME="red" VALUE="%(red)d" 
    onFocus="this.hasFocus = 1" onBlur="this.hasFocus=0"/></TD>
<TD><INPUT TYPE="text" NAME="red2" VALUE="%(red2)d" 
    onFocus="this.hasFocus = 1" onBlur="this.hasFocus=0"/></TD>
</TR>
<TR>
<TD>Green</TD>
<TD><INPUT TYPE="text" NAME="green" VALUE="%(green)d"
    onFocus="this.hasFocus = 1" onBlur="this.hasFocus=0"/></TD>
<TD><INPUT TYPE="text" NAME="green2" VALUE="%(green2)d"
    onFocus="this.hasFocus = 1" onBlur="this.hasFocus=0"/></TD>
</TR>
<TR>
<TD>Blue</TD>
<TD><INPUT TYPE="text" NAME="blue" VALUE="%(blue)d"
    onFocus="this.hasFocus = 1" onBlur="this.hasFocus=0"/></TD>
<TD><INPUT TYPE="text" NAME="blue2" VALUE="%(blue2)d"
    onFocus="this.hasFocus = 1" onBlur="this.hasFocus=0"/></TD>
</TR>
<TR>
<TD>Change Delay</TD><TD><INPUT TYPE="text" NAME="speed" VALUE="%(speed)d"
    onFocus="this.hasFocus = 1" onBlur="this.hasFocus=0"/></TD>
</TR>
<TR>
<TD>Or Choose a Predefined Color:</TD><TD>
<DIV STYLE="height:220;overflow:scroll;border:solid;">---select a color from the list---<br/>
%(colors)s
</DIV></TD>
</TR>
<TR>
<TD COLSPAN="2"><INPUT NAME="set_colors" TYPE="submit" VALUE="Set Colors"/><INPUT NAME="random" TYPE="submit" VALUE="Party Mode!"/>
<!--INPUT TYPE="submit" NAME="quit" VALUE="Stop Server" STYLE="background-color:red;"/-->
</TD>
</TR>
</TABLE>
<input type="hidden" name="color" value=""/>
</FORM>
</BODY>
"""
from colors import colors
import digiweb
import zigbee
from socket import *
import sys
import os
import select
import thread
import re
import time

sd = None
th = None
th2 = None
recvData = {}
exitRequest = False
nodeData = {}

def serverPage(type, path, headers, args):
    if args is not None:
        if type == "POST": args = splitargs(args)
    if path == "/lights":
        return colorPage(args)
    elif path == "/query":
        return query(args)
    else:
        return (digiweb.TextHtml,"<h1>Invalid URL</h1>")

def colorPage(args):
    socketVal = {'r': 0, 'g':0, 'b':0, 'r2':0, 'g2':0, 'b2':0}
    nodelist = []
    random_mode = False
    change_speed = 6
    change_speed_changed = False
    
    if args is not None:
        ignrgb = False
        for arg in args.keys():
            argkey = arg.lower()
            argval = args[arg]
            if argval is not None: argval = unquote(argval)
            print "key: "+argkey+" val: "+argval
            if not ignrgb and argkey == "red":
                socketVal['r'] = int(argval)
            elif not ignrgb and argkey == "green":
                socketVal['g'] = int(argval)
            elif not ignrgb and argkey == "blue":
                socketVal['b'] = int(argval)
            elif not ignrgb and argkey == "red2":
                socketVal['r2'] = int(argval)
            elif not ignrgb and argkey == "green2":
                socketVal['g2'] = int(argval)
            elif not ignrgb and argkey == "blue2":
                socketVal['b2'] = int(argval)
            elif argkey == "speed":
                change_speed = int(argval)
                change_speed_changed = True
            elif argkey == "color":
                if colors.has_key(argval.lower()):
                    socketVal = colors[argval.lower()]
                    for k in ('r','g','b'):
                        socketVal[k+"2"] = socketVal[k]
                    ignrgb = True
            elif argkey == "node":
                nodelist.append(argval)
            elif argkey == "random":
                random_mode = True
            elif argkey == "quit":
                print "Stopping server"
                sd.close()
                exitRequest = True
                sys.exit()
                return (digiweb.TextHtml, "exiting")
    
    if random_mode:
        socketdata = "n"
    else:
        if args is None or not args.has_key("red2"):
            socketdata = "A"+"".join([k+str(socketVal[k]) for k in ('r','g','b')])
        else:
            try:
                socketdata = "F"+"".join([k+str(socketVal[k]) for k in ('r','g','b')])
            except:
                pass
            try:
                socketdata += "C"+"".join([k[0]+str(socketVal[k]) for k in ('r2','g2','b2')])
            except:
                pass

        if change_speed_changed:
            socketdata += "s"+str(change_speed)
    
    socketdata += "\n"
    print "sending "+socketdata+" to "+str(nodelist) + "\n"
        
    if 'all' in nodelist:
        nodelist = nodeData.keys()

    for node in nodelist:
        try:
            sd.sendto(socketdata, 0, (node, 0xe8, 0xc105, 0x11))
        except:
            print "Failed to send to "+node
                
    nodeList = ""
    for node in nodeData.keys():
        try:
            nodeline = "<OPTION value='"+node+"'"
            if node in nodelist:
                nodeline += " selected"
            nodeline += ">"+\
                nodeData[node]['nodeId']+\
                "</OPTION>"
            nodeList += nodeline
        except:
            pass
    
    colorList = ""
    ckeys = colors.keys()
    ckeys.sort()
    for c in ckeys:
        comps = colors[c]
        luma=comps['r']*.3 + comps['g']*.59 + comps['b']*.11
        if luma < 128: textcolor = 'white' 
        else: textcolor = 'black'
        colorEntry = "<DIV style=\"background-color:#%02x%02x%02x;color:%s;text-align:center;margin:2px 0px;cursor:pointer;\" onclick=\"setcolor(this)\">%s</DIV>" % (comps['r'], comps['g'], comps['b'], textcolor, c)
        colorList += colorEntry

    if len(nodelist) > 0:
        try:
            nodeaddr = nodelist[0]
            nodeData[nodeaddr]['red'] = socketVal['r']
            nodeData[nodeaddr]['green'] = socketVal['g']
            nodeData[nodeaddr]['blue'] = socketVal['b']
            nodeData[nodeaddr]['red2'] = socketVal['r2']
            nodeData[nodeaddr]['green2'] = socketVal['g2']
            nodeData[nodeaddr]['blue2'] = socketVal['b2']
            if change_speed_changed:
                nodeData[nodeaddr]['speed'] = change_speed
        except:
            exctype, value = sys.exc_info()[:2]
            print "failed to update nodeData: "+str(exctype)+", "+str(value)
    elif len(nodeData) > 0:
        nodeaddr = nodeData.keys()[0]
        socketVal = { 'r': nodeData[nodeaddr]['red'],
            'g': nodeData[nodeaddr]['green'],
            'b': nodeData[nodeaddr]['blue'],
            'r2': nodeData[nodeaddr]['red2'],
            'g2': nodeData[nodeaddr]['green2'],
            'b2': nodeData[nodeaddr]['blue2'] }

    return (digiweb.TextHtml, web_template % {
            'red':socketVal['r'], 'green':socketVal['g'], 'blue':socketVal['b'],'speed':change_speed,
            'red2':socketVal['r2'], 'green2':socketVal['g2'], 'blue2':socketVal['b2'],
            'nodes':nodeList, 'colors':colorList })

xmlTemplate = """
<lights>
    %s
</lights>
"""
lightTemplate = """
<light node="%(nodeaddr)s">
    <red>%(red)d</red>
    <green>%(green)d</green>
    <blue>%(blue)d</blue>
    <red2>%(red2)d</red2>
    <green2>%(green2)d</green2>
    <blue2>%(blue2)d</blue2>
    <speed>%(speed)d</speed>
    <nodeId>%(nodeId)s</nodeId>
    <lastActive>%(active)f</lastActive>
</light>\n
"""
jsonTemplate="""
{"lights": [%s]"}
"""
jsonLightTemplate="""
{"red":%(red)d, "green":%(green)d, "blue":%(blue)d, "speed":%(speed)d,
 "nodeId":"%(nodeId)s", "lastActive":%(active)f}
"""
def query(args):
    lightData = ""
    template = ""
    itemplate = ""
    fmt = "xml"
    if args is not None and args.haskey('fmt') and args['fmt'] == 'json':
        fmt = args['fmt']
        template = jsonTemplate
        itemplate = jsonLightTemplate
    else:
        template = xmlTemplate
        itemplate = lightTemplate

    for nodeInfo in nodeData.keys():
        if fmt == 'json' and lightData.length > 0:
            lightData += ","
        lightData += itemplate % nodeData[nodeInfo]
    ret = (digiweb.TextXml, template % (lightData,))
    print "returning query data "+ret[1]+"\n"
    return ret

def splitargs(arglist):
    ret = {}
    for arg in arglist.split("&"):
        argsp = arg.split('=')
        if len(argsp) == 1:argsp.append(None)
        ret[argsp[0]] = argsp[1]
    return ret
    
def parseQ():
    pat = "Qr(\d+)g(\d+)b(\d+)s(\d+)"
    pat2 = "2r(\d+)g(\d+)b(\d+)"
    for nodeaddr,text in recvData.items():
        match = re.search(pat, text)
        if match is not None:
            print "found match"
            try:
                nodeName = zigbee.ddo_get_param(nodeaddr, "NI")
                if not nodeData.has_key(nodeaddr):
                    nodeData[nodeaddr] = {
                        "red":0, "green":0, "blue":0, "speed":0,
                        "red2":0, "green2":0, "blue2":0,
                        "nodeaddr":nodeaddr, "nodeId":nodeName
                    }
                else:
                    nodeData[nodeaddr]["nodeId"] = nodeName
            except:
                exctype, value = sys.exc_info()[:2]
                print "failed to add node: "+str(exctype)+", "+str(value)
                continue
            recvData[nodeaddr] = ""
            nodeData[nodeaddr]['red'] = int(match.group(1))
            nodeData[nodeaddr]['green'] = int(match.group(2))
            nodeData[nodeaddr]['blue'] = int(match.group(3))
            nodeData[nodeaddr]['red2'] = int(match.group(1))
            nodeData[nodeaddr]['green2'] = int(match.group(2))
            nodeData[nodeaddr]['blue2'] = int(match.group(3))
            nodeData[nodeaddr]['speed'] = int(match.group(4))
            nodeData[nodeaddr]['active'] = time.time()
        match = re.search(pat2, text)
        if match is not None:
            print "found match2"
            recvData[nodeaddr] = ""
            nodeData[nodeaddr]['red2'] = int(match.group(1))
            nodeData[nodeaddr]['green2'] = int(match.group(2))
            nodeData[nodeaddr]['blue2'] = int(match.group(3))
            nodeData[nodeaddr]['active'] = time.time()

def monitor_read(sock):
    rlist = [sock]
    while not exitRequest:
        select.select(rlist, [], [])
        payload, addr = sock.recvfrom(8192)
        print "received "+payload+" from "+str(addr)+"\n"
        if not recvData.has_key(addr[0]):
            recvData[addr[0]] = payload
        else:
            recvData[addr[0]] += payload
        parseQ()
            
        if len(recvData[addr[0]]) > 500:
            recvData[addr[0]] = recvData[addr[0]][-500:]
        time.sleep(1)
    print "goodbye from monitor_read\n"
    
def query_params(sock):
    print "starting query params\n"
    while not exitRequest:
        try:
            nodes = zigbee.get_node_list(True)
            for n in nodes:
                print "sending query to "+n.addr_extended
                sock.sendto("AQ\n", 0, (n.addr_extended, 0xe8, 0xc105, 0x11))
        except:
            exctype, value = sys.exc_info()[:2]
            print "failed to query node: "+str(exctype)+", "+str(value)
        time.sleep(30)
    print "goodbye from query_params\n"

def unquote(str):
    str = str.replace('+',' ')
    str = re.sub('%[\da-fA-F]{2}', lambda(x) : chr(int(x.group(0)[1:],16)), str)
    return str

if __name__ == "__main__":
    sd = socket(AF_XBEE, SOCK_DGRAM, XBS_PROT_TRANSPORT)
    sd.bind(("", 0xe8, 0, 0))
    sd.setblocking(0)

    th = thread.start_new(monitor_read, (sd,))
    th2 = thread.start_new(query_params, (sd,))
    
    hnd = digiweb.Callback(serverPage)
    
    print "ready"
    while True: 
        time.sleep(60)
        pass
   
