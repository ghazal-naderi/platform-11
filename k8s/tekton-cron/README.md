# tekton-cron
The struct allows for the creation of a tekton cron that allows for the scheduling of pipeline runs on a schedule.

At the moment the manifests are set up in such a way that they hit the tekton cronjob event listener every 5 minutes and can be changed in this file tekton-cronjob.yaml, on this line 

  ```
  schedule: "*/5 * * * *"
  ```
  
Different listeners can be configured for the cron by changing this configuration 

  el-cron-listener.tekton-pipelines.svc.cluster.local:8080
  
Note that the currect configuration of the manifests are to always trigger the infra-cd pipeline, this can be configured in the file tekton-cronjob-eventlistener.yaml by changing the trigger template.

      template:
        name: infra-cd

Finally in order to trigger off the correct repo you will need to change the TriggerBinding resource which is configured in the tekton-cronjob-triggerbinding.yaml file.

```
  - name: gitrepositoryurl
    value: https://github.com/AvaBank/infra
```
