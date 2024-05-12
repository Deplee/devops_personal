package ru.lcgroup.jenkins.lib
class Rocket implements Serializable {
    def steps

    Rocket(steps) { this.steps = steps }

    def rocketNotify(String channel, String id, String token, String buildResult = null, String title, String text, Date startDate = null, Date stopDate = null, String debugUrl = null) {
        
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

        //end of build time
        //POST URL
        //debug httpecho:
    //        def chat_url = "http://echo-mendhack:8080"
        //production:
        def chat_url = "https://url:port/api/v1/chat.postMessage"
        if (debugUrl != null) {
            chat_url = debugUrl
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
        } //${env.channel}
        
        def msg =
                """
                    {
                        "channel": "${channel}",
                        "alias": "Rocket Notify",
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

        steps.httpRequest   httpMode: 'POST',
                            customHeaders: [[name: "X-Auth-Token", value: token],
                                            [name: "X-User-Id", value: id]],
                            url: chat_url,
                            contentType: 'APPLICATION_JSON_UTF8',
                            requestBody: msg
    }
}
