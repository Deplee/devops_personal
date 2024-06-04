package domain.subdomain.jenkins.lib
import groovy.json.*
class rtst implements Serializable {
    
    def steps
    def response
    def chat_url
    def msg

    Rocketatst(steps) { this.steps = steps }

    def rocketNotify(String channel, String id, String token, String method = null, String rediskey = null, String buildResult = null, String title, String text, Date startDate = null, Date stopDate = null, String debugUrl = null) {
        
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

        //debug httpecho:
        //def chat_url = "http://ip:8080"
        //production:
        
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

        def webdis_uri = 'http://192.168.1.123:7379/'
        def webdis_body = 'GET/' + "${rediskey}"

        if (method == 'start') {
            chat_url = "https://url:port/api/v1/chat.postMessage"
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
       } else if  (method == 'end') {
            chat_url = "https://url:port/api/v1/chat.sendMessage"
            def  postToRedis =  steps.httpRequest   httpMode: 'POST',
                                    url: webdis_uri,
                                    requestBody: webdis_body
            def slurp = new JsonSlurper().parseText(postToRedis.content)
            def tmid = slurp.GET
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

        } else {
            println('[ERROR]')
        }
        
        response = steps.httpRequest  httpMode: 'POST',
                        customHeaders: [[name: "X-Auth-Token", value: token],
                                        [name: "X-User-Id", value: id]],
                        url: chat_url ,
                        contentType: 'APPLICATION_JSON_UTF8',
                        requestBody: msg
        steps.httpRequest   httpMode: 'POST',
                        url: webdis_uri,
                        requestBody: 'DEL/' + "${rediskey}"
    }
@NonCPS
def setKey(String rediskey){
    def slurper = new JsonSlurper().parseText(response.content)
    def tmid = slurper.message._id
    def webdis_uri = 'http://192.168.1.123:7379/'
    def webdis_body = 'SET/' + "${rediskey}" + '/' + tmid // + test_id // message id for new thread: 2tqxcnmah2cxTBjvF
            
       steps.httpRequest   httpMode: 'POST',
                                url: webdis_uri,
                                requestBody: webdis_body
    
    }
}

