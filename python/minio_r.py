import redis
import json
import requests
import docker
import os

class redis_script:
    # setting variables
    conn = redis.Redis('localhost')
    client = docker.from_env()
    dockerNameTag = 'doc-templates:latest'
    cmd_commit = 'docker commit doc-templates-minio gitlab..com/path/torepo/' + dockerNameTag
    # ex HSET Lime_Templates_AreDirty TemplateName tpl1 Comment xxx UploadOn 2023-04-21T13:56:03.932743+07:00
    hashName = name:name-doc:Templates:AreDirty"
    key = "TemplateName"
    keys = ["TemplateName" , 'Comment', "UploadOn"]
    chat_url = "https://url:port/api/v1/chat.postMessage"
    headers = { 'Content-Type' : 'application/json',
    'X-Auth-Token': '*',
    'X-User-Id': '*'}
    channel = "#david-tst"
    print(conn.hgetall(hashName))

    def master(self):
        try:
            if (self.conn.hexists (self.hashName, self.key)):
                redis_data = self.conn.hgetall(self.hashName)
                print(redis_data)
                msg_text = []
                # count of vars in redis hashmap
                count = len(redis_data)
                #for k in range(count):
                keysOutput_0 = self.conn.hget(self.hashName, self.keys[0])
                keysOutput_1 = self.conn.hget(self.hashName, self.keys[1])
                keysOutput_2 = self.conn.hget(self.hashName, self.keys[2])
                    #keysOutput_f = json.loads(keysOutput)
                #print(list_text)
                msg_text.append("\nTemplate: **%s** \nComment: **%s** \nUploadOn: **%s**" %(keysOutput_0,keysOutput_1,keysOutput_2))
                #print(list_text)

                # start docker operations

                if (self.conn.hexists(self.hashName,self.key) == True):
                    self.client.login(username='gituser', password=None, email=None,
                                      registry='gitlab.lcgs.ru/russia/backend/', dockercfg_path='/path/to/config.json')
                    os.system(self.cmd_commit)
                for line in self.client.images.push('gitlab.lcgs.ru/russia/backend/' + self.dockerNameTag, stream=True, decode=True):
                    print(line)
            else:
                print("Something in redis gonna wrong!")
                msg_text = "Error"
        except Exception as err:
            print(err)
        finally:
        # Notify rocketchat
            data =          {
                    "channel": self.channel,
                    "alias": "Devops Redis Notifier",
                    "avatar": "https://icon-icons.com/downloadimage.php?id=146368&root=2415/PNG/128/&file=redis_original_logo_icon_146368.png",
                    "text": msg_text,
                    "color": "#C6201E",
                }
            # post msg in rocket.chat
            response = requests.post(self.chat_url, headers=self.headers, json=data)
            print("Status Code", response.status_code)
            print("JSON Response ", response.json())
            if (response.status_code == 200):
                print("===MESSAGE SUCCESFULY DELIVERED===")
            else:
                print("===MESSAGE NOT DELIVERED===")

if __name__ == "__main__":
    try:
        conn = redis.Redis('127.0.0.1')
        ping = conn.ping()
        print('Connected to redis: "{}"'.format(conn))
    except Exception as err:
        print("Redis host is not available!\nPing not succeed!")
    finally:
        t = redis_script()
        t.master()
