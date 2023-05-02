
# # Import the Redis client

import redis
import requests
import json


class script:

    # # Create a redis client
    redisClient = redis.StrictRedis(host='127.0.0.1',port=6379,db=0,charset="utf-8", decode_responses=True)
    # # Set redis hashmap name
    hashName = "Lime_Templates_IsDirty"
    # # Set redis keys
    post_data1 = redisClient.hget(hashName,"TemplateName")
    post_data2 = redisClient.hget(hashName,"Comment")
    post_data3 = redisClient.hget(hashName,"UploadOn")
    key = "TemplateName"
    
    if (redisClient.hexists(hashName,key) == True):
        # # Text formatting
        text = "\nKey_1: " + "**" + post_data1 + "**" + " " + " \nKey_2: " + " " + "**" + post_data2 + "**" + " " + " \nKey_3: " + " " + "**" + post_data3 + "**" 
        # # Get all keys from hashmap
        all_keys = list(redisClient.hgetall(hashName).keys())
        # # Delete hashmap & keys
        redisClient.hdel(hashName, *all_keys)
        print("\nHashmap" + " " + hashName + " "  + "removed \n")
    else:
        # # Text formatting
        text = "\n Hashmap" + " " + "**" + hashName +"**" + " "  + "not exists"
        
    # # Rocket.Chat post msg function
    def rocket_notify(self):
        data = {
                            "channel": "#devops-tst",
                            "alias": "TST-redis-notify",
                            "avatar": "https://icon-icons.com/downloadimage.php?id=146368&root=2415/PNG/128/&file=redis_original_logo_icon_146368.png",
                            "text": self.text,
                            "color": "#C6201E",
                        }
        chat_url = "https://chat.lime-zaim.ru:30500/api/v1/chat.postMessage"
        #chat_url = "http://192.168.1.207:8080"
        print (chat_url)
        headers = { 'Content-Type' : 'application/json',
        'X-Auth-Token': 'k5tDfe9qBOde2m3HwF9THRQLUi2_Ms1wGdMhQ-pD3OA',
        'X-User-Id': 'xJ9qFMvZmMqp9xQ9S'}
        response = requests.post(chat_url, headers=headers, json=data)

        print("Status Code", response.status_code)
        print("JSON Response ", response.json())



t = script()
t.rocket_notify()

