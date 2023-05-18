# # Import the Redis client
#gitlab.lcgs.ru/devops/jenkins/ssh-agent-nix-ansible
import redis
import requests
import json
import os
import docker
from pprint import pprint




class script:

    # # Create a redis client
    redisClient = redis.StrictRedis(host='127.0.0.1',port=6379,db=0,charset="utf-8", decode_responses=True)

    # # Set redis hashmap name
    hashName = "name:name"

    # # Save redis keys in variables
    redis_data = redisClient.hget(hashName,"data")
    key = "data"


    # # Set docker variables & login
    dockerNameTag = 'tag:latest'
    client = docker.from_env()
    client.login(username='*user*', password=None, email=None,
                        registry='https://url', dockercfg_path='/path/to/config.json')
    cmd_commit = 'docker commit *name* *tag+url*' + dockerNameTag

    # # Parse JSON
    json_data = json.loads(redis_data)
    count = len(json_data)
    if (redisClient.hexists(hashName,key) == True):

        # # Commit container
        os.system(cmd_commit)
        # # Push container
         for line in client.images.push('gitlab.lcgs.ru/devops/jenkins/' + dockerNameTag, stream=True, decode=True):
             print(line)

        # # Text formatting
        list_text = []
        for k in range(count):
            list_text.append("\n**Template**: **%s** \nComment: %s \nUpload: %s\n" % (json_data[k]['Template'],json_data[k]['Comment'],json_data[k]['UploadOn']))

        # # Convert from list text to string text
        string_text =(" ".join(list_text))
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
        data =          {
                            "channel": "#channel",
                            "alias": "*name",
                            "avatar": "https://icon-icons.com/downloadimage.php?id=146368&root=2415/PNG/128/&file=redis_original_logo_icon_146368.png",
                            "text": self.string_text,
                            "color": "#C6201E",
                        }
        chat_url = "https://url:port/api/v1/chat.postMessage"
        print (chat_url)
        headers = { 'Content-Type' : 'application/json',
        'X-Auth-Token': '*',
        'X-User-Id': '*'}
        response = requests.post(chat_url, headers=headers, json=data)

        print("Status Code", response.status_code)
        print("JSON Response ", response.json())

if __name__ == "__main__":

    t = script()
    t.rocket_notify()

