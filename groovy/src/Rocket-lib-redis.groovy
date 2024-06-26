package tst.tst.jenkins.lib
import groovy.json.*
class Rocketatst implements Serializable {
    
    def steps
    def response
    def chat_url
    def msg
    def tmid

    Rocketatst(steps) { this.steps = steps }

    def rocketNotify(String channel, String id, String token, String redisKey = null, String buildResult = null, String title, String text, Date startDate = null, Date stopDate = null, String debugUrl = null) {
        
        String textVal=""
        if (startDate == null ||  stopDate == null ) {
            textVal="${text}"
        } 
        else {
            // start of build time
            long dateStart = startDate.getTime();
            long dateStop = stopDate.getTime();
            long diffirence = dateStop - dateStart;

            long secondInMillis = 1000;
            long minuteInMillis = secondInMillis * 60;
            long hourInMillis = minuteInMillis * 60;
            long dayInMillis = hourInMillis * 24;

            long diffMin = diffirence / minuteInMillis;
            diffirence = diffirence % minuteInMillis; 
            long diffSec = diffirence / secondInMillis;
            
            textVal="${text} Build Time: *${diffMin} mins and ${diffSec} seconds*"
        }

        
        def msg_colors = [
            "SUCCESS" : "#329B59",
            "FAILURE" : "#C6201E",
            "CANCELED": "#B0B0B0"
        ]
        def msg_color = ""

        switch (buildResult) {
            case "SUCCESS":
                msg_color = msg_colors['SUCCESS']
                break
            case ~/FAILURE(.*)/:
                msg_color = msg_colors['FAILURE']
                break
            case "CANCELED":
                msg_color = msg_colors['CANCELED']
                break
        }

        chat_url = "https://url:port/api/v1/chat.postMessage"
        def webdis_uri = 'http://ip:7379/'
        if (true) {
            def webdiscmd = 'GET/' + "${redisKey}"
            def  postToRedis =  steps.httpRequest   httpMode: 'POST',
                                    url: webdis_uri,
                                    requestBody: webdiscmd
            def slurp = new JsonSlurper().parseText(postToRedis.content)
            tmid = slurp.GET
        }
        
        if (!tmid) {
            msg =
                    """
                        {
                            "channel": "${channel}",
                            "alias": "Jenkins Rocket Notifier",
                            "avatar": "https://icon-icons.com/downloadimage.php?id=170552&root=2699/PNG/512/&file=jenkins_logo_icon_170552.png",
                            "attachments": [
                                {
                                    "title": "${title}",
                                    "color": "${msg_color}",
                                    "collapsed": true,
                                    "fields": [
                                        {
                                            "title": "",
                                            "value": "${textVal}",
                                            "short": false
                                        }
                                    ]
                                }
                            ]
                        }
                    """
        } else {
            chat_url = "https://url:port/api/v1/chat.sendMessage"
            msg = """
                        {
                            "message": {
                                "rid": "${channel}",
                                "tmid": "${tmid}",
                                "alias": "Jenkins Rocket Notifier",
                                "avatar": "https://icon-icons.com/downloadimage.php?id=170552&root=2699/PNG/512/&file=jenkins_logo_icon_170552.png",
                                "attachments": [
                                {
                                    "title": "${title}",
                                    "color": "${msg_color}",
                                    "collapsed": true,
                                    "fields": [
                                    {
                                        "title": "",
                                        "value": "${textVal}",
                                        "short": false
                                    }
                                    ]
                                }
                                ]
                            }
                        }
                    """
       }
        
        response = steps.httpRequest  httpMode: 'POST',
                        customHeaders: [[name: "X-Auth-Token", value: token],
                                        [name: "X-User-Id", value: id]],
                        url: chat_url ,
                        contentType: 'APPLICATION_JSON_UTF8',
                        requestBody: msg
        if (true && !tmid) {
            def slurper = new JsonSlurper().parseText(response.content)
            def tmid = slurper.message._id
            def webdiscmd = 'SETEX/' + "${redisKey}/18000/" + tmid // + test_id // message id for new thread: 2tqxcnmah2cxTBjvF
            steps.httpRequest   httpMode: 'POST',
                                    url: webdis_uri,
                                    requestBody: webdiscmd  
        }
    }
}

