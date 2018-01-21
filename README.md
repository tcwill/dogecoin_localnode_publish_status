# dogecoin_localnode_publish_status

An extra crusty bash script to generate an HTML status page on a Dogecoin node.

Works by replacing known tokens/placeholders in an HTML template with actual values from dogecoind on the local node.  Values are acquired with dogecoin-cli

Requires: dogecoin (core) full wallet on the same system as a webserver that can serve static pages.

Intended usage is to run from crontab to update static HTML status page on some regular basis.

## Dear god, why?

Well, I set up dogecoind on a VPS and wanted to be able to get some basic information from the daemon w/out logging into the box.  I also had no interest in using the dogecoin RPC facilities.  Oh, and I like generating static webpages, and bash scripts.

I tried to minimize dependecies on anything outside of basic shell tools.

## Current list of known tokens for the HTML template:
* DOGEUPDATE - Date/time of script execution in UTC
* DOGEBLOCK - The current height of the dogecoin blockchain as reported by the local node
* DOGECONN - Current number of connections reported by dogecoin
* BYTERCVD - bytes recieved (MB received)
* BYTESENT - bytes send (MB sent)
* DOGEWALLET - public address of the wallet you specified with the script's -w option 

## Help text:

usage:
```
node_stat.sh -d <dir> [-o <file>] [-t <file>] [-w <public address>]
```
where:

-d  
Required!  provide the full path to your dogecoin install.  
Specified dir should be parent of bin/  
Ex.: /home/shibe/dogecoin-1.10.0  
default: none  

-o  
file location of desired output file.  
Tip: should probably be somewhere your webserver can serve it.  
Ex.: /var/www/html/stats.html  
default: no file; print to STDOUT  

-t  
file location of HTML input template.  
Ex.: /home/shibe/node_stats_template.html  
default: use the internally provided default template from the script  

-w  
the public address of your dogecoin wallet.  
The idea is the use this for advertising your wallet address if you're  
soliciting tips/support for running your node  
default: none  

-h  
print the script's help text

### Example crontab entry
to run every 2 minutes using the default template:
```
*/2 * * * * ~/node_stat.sh -d /home/shibe/dogecoin-1.10.0/ -o ~/public_html/doge.is.just.plain.cool/html/index.html -w DGup9xDx8y1ypytA3btuUdLe6368oEVwhU
```
by:  
Todd Williams  
tcwill@1dot0.io  
u/tcwill  

Shibe on!
