#!/bin/bash

usage="$(basename "$0") -d <dir> [-o <file>] [-t <file>] [-w <public address>]

An extra crusty script to generate an HTML status page on a Dogecoin Node.  
Works by replacing known tokens/placeholders with actual values from dogecoind on the local node.
Values are acquired with dogecoin-cli

Requires: dogecoin (core) full wallet on the same system as a webserver that can serve static pages.

Intended usage is to run from crontab to update static HTML status page on some regular basis.

Current list of known tokens for the HTML template:
DOGEUPDATE - Date/time of script execution in UTC
DOGEBLOCK - The current height of the dogecoin blockchain as reported by the local node
DOGECONN - Current number of connections reported by dogecoin
BYTERCVD - bytes recieved (MB received)
BYTESENT - bytes send (MB sent)
DOGEWALLET - public address of the wallet you specified with the script's -w option 
DOGEHOURS - number of hours the dogecoind process has been running on this host

where:
    -d  Required!  provide the full path to your dogecoin install.
        Specified dir should be parent of bin/
        Ex.: /home/shibe/dogecoin-1.10.0
        default: none
    -o  file location of desired output file.
        Tip: should probably be somewhere your webserver can serve it.
        Ex.: /var/www/html/stats.html
        default: no file; print to STDOUT
    -t  file location of HTML input template.
        Ex.: /home/shibe/node_stats_template.html
        default: use the internally provided default template from the script
    -w  the public address of your dogecoin wallet.
        The idea is the use this for advertising your wallet address if you're
        soliciting tips/support for running your node
        default: none

example entry in crontab to run every 2 minutes using the default template:
*/2 * * * * $(basename "$0") -d /home/shibe/dogecoin-1.10.0/ -o ~/public_html/doge.is.just.plain.cool/html/index.html -w DGup9xDx8y1ypytA3btuUdLe6368oEVwhU

by: 
Todd Williams
tcwill@1dot0.io
u/tcwill

Shibe on!
"

while getopts hd:o:t:w: opt
do
 case "${opt}"
 in
 h) echo "$usage"
    exit;;
 d) DOGEDIR=${OPTARG};;
 o) OUTFILE=${OPTARG};;
 t) TEMPLATEFILE=${OPTARG};;
 w) WALLET=${OPTARG};;
 esac
done

if [ ! -d "$DOGEDIR" ]; then
  ## yeah, let's require -d ARG
  echo "Please specify a valid directory using -d"
  echo "Specify -h for more information"
  exit 1
fi

if [ ! -z "$TEMPLATEFILE" ]; then
  USEDEFAULT=false ## template file provided, use it
else
  USEDEFAULT=true  ## no template provided, use the default template provided by the script
fi

# DOGEDIR should be the path to your dogecoin installation
# specifically it should be the directory which contains the dogecoin bin directory 
# this is required from the commandline via the -d opt
#DOGEDIR="/home/shibe/dogecoin-1.10.0"

BINDIR="${DOGEDIR}/bin"

# get the current date in UTC
LASTUPDATE=$(date -u)

## get some basic info: height of the chain on this node (this should be the same as the network), 
## and the number of connections: > 8 indicates your node is a "full" node and feeding other nodes on the network
## probably add some more output stats to this, like version, etc... 
GETINFO=$(${BINDIR}/dogecoin-cli getinfo )
DOGEBLOCK=$( <<< "${GETINFO}" grep blocks | awk -F ':' '{print $2}' | sed 's/\s\(.*\),/\1/g' )
DOGECONN=$( <<< "${GETINFO}" grep connections | awk -F ':' '{print $2}' | sed 's/\s\(.*\),/\1/g' )

## get network in/out stats
GETNETSTAT=$(${BINDIR}/dogecoin-cli getnettotals )
BYTESENT=$( <<< "${GETNETSTAT}" grep totalbytessent | awk -F ':' '{print $2}' | sed 's/\s\(.*\),/\1/g' )
BYTERCVD=$( <<< "${GETNETSTAT}" grep totalbytesrecv | awk -F ':' '{print $2}' | sed 's/\s\(.*\),/\1/g' )

## MB is easier to read than Bytes... so let figure that out.
MBSENT=$( expr $BYTESENT / 1048576 )
MBRCVD=$( expr $BYTERCVD / 1048576 )

SECRUNNING=$(DPID=`pgrep dogecoind`; ps -o etimes= -p "${DPID}")
HRSRUNNING=$( expr $SECRUNNING / 3600 )

# input html Template
# this template can contain the variables listed in the help for the script
# if you don't provide a template the script will output a rudimentary page

if [ $USEDEFAULT = false ]; then # OK, we've got a template
  PROVIDEDTEMPLATE=`cat $TEMPLATEFILE` # read in the template
fi


## provide a default HTML template to use in case none specified on commandline
DEFAULTTEMPLATE="<html>
<head>

<style>
body {
    background-color: #eee;
    color: #39f;
    font-family: \"Comic Sans MS\", \"Comic Sans\", cursive, sans-serif;
}
</style>

<title>So Doge</title>
</head>

<body>
<h1>very facts:</h1>
<ul>
<li>last update: DOGEUPDATE</li>
<li>dogecoin running for: DOGEHOURS hrs</li>
<li>so height: DOGEBLOCK</li>
<li>such connections: DOGECONN</li>
<li>bites recieved: BYTERCVD</li> 
<li>bites sent: BYTESENT</li>
</ul>
<h1>such wow!</h1>
<p>good doge?</p><p>plz support: <em>DOGEWALLET</em></p>
<p>Thanks shibe!</p>
<p>This status page is <a href="https://github.com/tcwill/dogecoin_localnode_publish_status">generated by bash</a></p>

</html>
"




if $USEDEFAULT; then
  if [ -z $WALLET ]; then
    DEFAULTTEMPLATE=$( <<< "${DEFAULTTEMPLATE}" grep -v "DOGEWALLET"  ) # no wallet specified, so rip the line that includes the DOGEWALLET var
  fi
  INSERTED=$( <<< "${DEFAULTTEMPLATE}" sed -e "s/DOGECONN/${DOGECONN}/g" \
              -e "s/DOGEBLOCK/${DOGEBLOCK}/g" \
              -e "s/DOGEUPDATE/${LASTUPDATE}/g" \
              -e "s/DOGEWALLET/${WALLET}/g" \
              -e "s/BYTERCVD/${BYTERCVD} \(${MBRCVD}MB\)/g" \
              -e "s/BYTESENT/${BYTESENT} \(${MBSENT}MB\)/g"  \
              -e "s/DOGEHOURS/${HRSRUNNING}/g"
            )
else  # you're not using the default... because you specified a template to read in
  INSERTED=$( <<< "${PROVIDEDTEMPLATE}" sed -e "s/DOGECONN/${DOGECONN}/g" \
              -e "s/DOGEBLOCK/${DOGEBLOCK}/g" \
              -e "s/DOGEUPDATE/${LASTUPDATE}/g" \
              -e "s/DOGEWALLET/${WALLET}/g" \
              -e "s/BYTERCVD/${BYTERCVD} \(${MBRCVD}MB\)/g" \
              -e "s/BYTESENT/${BYTESENT} \(${MBSENT}MB\)/g" \
              -e "s/DOGEHOURS/${HRSRUNNING}/g" 
            )
fi


if [ -z $OUTFILE ]; then   ## if no output file was specified...
  <<< $INSERTED cat        ## just write to STDOUT
else
  echo $INSERTED > $OUTFILE  ## outfile was specified, so write to it
fi

exit 0


