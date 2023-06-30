# # Import the Redis client
import redis
import requests
import json
import os
import docker
from pprint import pprint
import schedule
import time


class script:

    # # Create a redis client
    redisClient = redis.StrictRedis(host='127.0.0.1',port=6379,db=0,charset="utf-8", decode_responses=True)
    client = docker.from_env()
    # # Set redis hashmap name
    #hashName = "Lime:Doc:Lime_Templates_IsDirty"
    hashName = "Name:Doc:Templates:AreDirty"

    # # Save redis keys in variables
    key = "data"
    redis_data = redisClient.hget(hashName,key)

    # # Set docker variables & login
    dockerNameTag = 'doc-templates:latest'
    #cmd_commit = 'docker commit minio gitlab.lcgs.ru/russia/misc/blockersanalyzer/' + dockerNameTag
    cmd_commit = 'docker commit minio gitlab.domain/repo' + dockerNameTag
    # # Text formatting
    list_text = []

    # # Rocket.Chat post msg function
    def func(self):
        if (self.redisClient.hexists(self.hashName,self.key) == True):
            self.client.login(username='gituser', password=None, email=None,
                        registry='gitlab.domain/repo', dockercfg_path='/path/to/config.json')
            # # Commit container
            os.system(self.cmd_commit)
            # # Push container
            #for line in client.images.push('gitlab.lcgs.ru/russia/misc/blockersanalyzer/' + dockerNameTag, stream=True, decode=True):
            for line in self.client.images.push('gitlab.domain/repo' + self.dockerNameTag, stream=True, decode=True):
                print(line)
            # # Parse JSON
            json_data = json.loads(self.redis_data)
            print(json_data)
            count = len(json_data)
            #list_text = []
            for k in range(count):
                self.list_text.append("\nTemplate: **%s** \nComment: %s \nUpload: %s\n" % (json_data[k]['Template'],json_data[k]['Comment'],json_data[k]['UploadOn']))
            # # Convert from list text to string text
            #string_text =(" ".join(list_text))
            string_text =(" ".join(self.list_text))
            # # Get all keys from hashmap
            all_keys = list(self.redisClient.hgetall(self.hashName).keys())
            # # Delete hashmap & keys
            self.redisClient.hdel(self.hashName, *all_keys)
            print("\nHashmap" + " " + self.hashName + " "  + "removed \n")
            #final_text = (" ".join(self.list_text))
            # print("-------")
            # print(self.list_text)
            data =          {
                                "channel": "#dev-tst",
                                "alias": "TST-redis-notify",
                                "avatar": "https://icon-icons.com/downloadimage.php?id=146368&root=2415/PNG/128/&file=redis_original_logo_icon_146368.png",
                                "text": string_text,
                                "color": "#C6201E",
                            }
            chat_url = "https://url:port/api/v1/chat.postMessage"
            #chat_url = "http://url:port"
            headers = { 'Content-Type' : 'application/json',
            'X-Auth-Token': 'k5tDfe9qBOde2m3HwF9THRQLUi2_Ms1wGdMhQ-pD3OA',
            'X-User-Id': 'xJ9qFMvZmMqp9xQ9S'}
            response = requests.post(chat_url, headers=headers, json=data)

            print("Status Code", response.status_code)
            print("JSON Response ", response.json())
        else:
            print("\n Hashmap" + " " + "**" + self.hashName +"**" + " "  + "not exists")
if __name__ == "__main__":

    t = script()
    try:
        rs = redis.Redis("localhost")
        ping = rs.ping()
        print('Connected to redis: "{}"'.format(rs))
        t.func()
        #schedule.every(1).minutes.do(t.func)
        #schedule.every(10).seconds.do(t.func)
    except Exception as err:
        print("Redis host is not available!\nPing not succeed!")
        exit(1)
        #print("Exception err")
    # finally:
    #    #t.rocket_notify()
    # #    t.func()
    #    #print("finally")


# while True:
#     schedule.run_pending()
#     time.sleep(1)
