#!/bin/bash

echo "[+] Creating files"
mkdir -p /home/pi/web/templates/
touch /home/pi/web/app.py
touch /home/pi/web/templates/index.html
touch /home/pi/mode.sh
touch /home/pi/networkcount.sh
touch /home/pi/kismetstatus.sh

chmod +x /home/pi/mode.sh
chmod +x /home/pi/networkcount.sh
chmod +x /home/pi/kismetstatus.sh

sleep .5
echo "[+] Writing /home/pi/mode.sh"
cat << '_EOF_' > /home/pi/mode.sh
#!/bin/bash
GPSLINE=`gpspipe -w | head -10 | grep TPV | head -1`
GPSMODE=`echo $GPSLINE | sed -r 's/.*"mode":([0-9]).*/\1/'`
echo $GPSMODE > /home/pi/gpsmode
_EOF_

sleep .5
echo "[+] Writing /home/pi/networkcount.sh"
cat << '_EOF_' > /home/pi/networkcount.sh
#!/bin/bash
FILE=`ls -lt /home/pi/kismet/*.nettxt | head -n 1`
RECENTFILE=`echo $FILE | sed -r 's/.*[0-9][0-9]:[0-9][0-9] (.*.nettxt)/\1/'`
NET=`cat $RECENTFILE | grep ^Network | tail -n 1`
echo $NET | sed -r 's/.*Network ([0-9]*).*/\1/' > /home/pi/netcount
_EOF_

sleep .5
echo "[+] Writing /home/pi/kismetstatus.sh"
cat << '_EOF_' > /home/pi/kismetstatus.sh
#!/bin/bash

ps cax | grep kismet_server > /dev/null

if [ $? -eq 0 ]; then
  echo "kismet_server is running" > /home/pi/procstat
else
  echo "kismet_server is not running" > /home/pi/procstat
fi
_EOF_

sleep .5
echo "[+] Writing /home/pi/web/app.py"
cat << 'HEREBEDRAGONS' > /home/pi/web/app.py
#!/usr/bin/env python

from flask import Flask, render_template, request, redirect, url_for
import os

app = Flask(__name__)

@app.route('/', methods=['GET'])
def index(data=None, xmlfiles=None,gps=None,netcount=None):
    os.system('/home/pi/mode.sh')
    with open("/home/pi/gpsmode") as myfile:
        gps = myfile.read()
    myfile.close()

    os.system('/home/pi/kismetstatus.sh')
    with open("/home/pi/procstat") as myfile:
        data = myfile.read()
    myfile.close()

    os.system('/home/pi/networkcount.sh')
    with open("/home/pi/netcount") as myfile:
        netcount = myfile.read()
    myfile.close()

    xmlfiles = [name for name in os.listdir('/home/pi/kismet/') if name.endswith('.netxml')]

    return render_template('index.html',data=data,xmlfiles=xmlfiles,gps=gps,netcount=netcount)

@app.route('/pressed/', methods=['POST'])
def pressed():
    button = request.form['button']
    if button == "START":
        os.system('/etc/init.d/kismet start &')
    elif button == "STOP":
        os.system('/etc/init.d/kismet stop &')
    return redirect(url_for(('index')))

if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=8080)
HEREBEDRAGONS

sleep .5
echo "[+] Writing /home/pi/web/templates/index.html"
cat << 'TANSTAAFL' > /home/pi/web/templates/index.html
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8" />
    <title>WarPi</title>
  </head>
<body>
  <form>
    <fieldset>
      <legend>WarPi Status</legend>
        <h2>Kismet status: {{ data }}</h2>
        <h2>GPS Mode: {{ gps }}</h2>
        <h2>Network count observed: {{ netcount }}</h2>
    </fieldset>
  </form>
  <br>
  <form action="/pressed/" method="POST">
    <fieldset>
      <legend>Buttons</legend>
      <button name="button" value="START" type=submit>START kismet_server</button>&nbsp;
      <button name="button" value="STOP" type=submit>STOP kismet_server</button><br>
    </fieldset>
  </form>
  <br>
  <form>
    <fieldset>
      <legend>.netxml Files</legend>
      {% for item in xmlfiles %}
  	  <input type="radio" name="file" value="{{ item }}">{{ item }}<br>
      {% endfor %}
    </fieldset>
  </form>
</html>
TANSTAAFL

sleep 1
echo "[+] Web app install complete"
echo "[+] Run with: sudo python /home/pi/web/app.py"
echo "    Access: http://<WarPi_IP>:8080"
