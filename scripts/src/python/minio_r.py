import redis
import requests
import json
import os
import docker
class script:

    # # VARS:
    # # set rocket.chat channel name
    channel = '#channel'
    # # docker & git cfg
    gitRepo = 'gitlab.com/path/to/repo'
    dockerTag = 'tag:latest'
    dockerUser = 'gituser'
    dockerconfigPath = '/path/to/config.json'
    # # Create a redis client
    redisClient = redis.StrictRedis(host='localhost',port=6379,db=0,charset="utf-8", decode_responses=True)
    # # Set redis hashmap name & headKey for search in redis
    # example redis input: HSET Lime_Templates_AreDirty TemplateName tpl1 Comment xxx UploadOn 2023-04-21T13:56:03.932743+07:00
    hashName = "HashName"
    headKey = "HeadKeyName"
    redis_data = redisClient.hgetall(hashName)
    # # Set docker vars
    dockerClient = docker.from_env()
    dockerContainerName = 'docker container name'
    # # System CMDs
    cmd_commit = 'docker container commit ' + dockerContainerName + ' ' +  gitRepo + '/' + dockerTag
    
    # # Check redis & send rocket.chat notification function
    def master_func(self):
        if (self.redisClient.hexists(self.hashName,self.headKey) == True):
            self.dockerClient.login(username=self.dockerUser, password=None, email=None,
                              registry=self.gitRepo, dockercfg_path=self.dockerconfigPath)
            
            # # Commit container
            os.system(self.cmd_commit)
            # # Push container
            for push_info in self.dockerClient.images.push(self.gitRepo + '/' + self.dockerTag, stream=True, decode=True):
                print(push_info)

            # # From Redis to String
            json_str = json.dumps(self.redis_data)
            json_data_dict = json.loads(json_str)

            list_text = []
            list_text.append("\nTemplate: **%s** \nComment: **%s** \nUpload: **%s**\n" % (json_data_dict['TemplateName'],json_data_dict['Comment'],json_data_dict['UploadOn']))
            
            # # Convert from list text to string text
            string_text =(" ".join(list_text))
            # # Get all keys from hashmap
            all_keys = list(self.redisClient.hgetall(self.hashName).keys())
            # # Delete hashmap & keys
            self.redisClient.hdel(self.hashName, *all_keys)
            print("\nHashmap" + " " + self.hashName + " "  + "removed \n")
            data =          {
                                "channel": self.channel,
                                "alias": "TST-redis-notify",
                                "avatar": "https://icon-icons.com/downloadimage.php?id=146368&root=2415/PNG/128/&file=redis_original_logo_icon_146368.png",
                                "text": string_text,
                                "color": "#C6201E",
                            }
            chat_url = "https://url:port/api/v1/chat.postMessage"
            headers = { 'Content-Type' : 'application/json',
            'X-Auth-Token': '*',
            'X-User-Id': '*'}
            response = requests.post(chat_url, headers=headers, json=data)
            if (response.status_code == 200):
                print("===MESSAGE SUCCESFULY DELIVERED===")
            else:
                print("JSON Response ", response.json())
                print("===MESSAGE NOT DELIVERED===")     
            print("Status Code", response.status_code)
        else:
            print("\n Hashmap" + " " + "**" + self.hashName +"**" + " "  + "not exists")

if __name__ == "__main__":

    t = script()
    try:
        rs = redis.Redis('127.0.0.1')
        ping = rs.ping()
        print('Connected to redis: "{}"'.format(rs))
    except Exception as err:
        print("Redis host is not available!\nPing not succeed!")
        exit(1)
    finally:
        t.master_func()

