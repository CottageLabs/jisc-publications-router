# Using JiscPublicationsRouter gem

1. Install the gem

   ```
   gem install ./jisc_publications_router-0.1.0.gem
   ```

   or add it to your Gemfile and bundle install

   ```
   # Gemfile
   gem 'jisc_publications_router', git: 'https://gitlab.bodleian.ox.ac.uk/ORA4/jisc-publications-router'
   ```

   ```
   bundle install
   ```


## Using the gem

**Configure the gem**

The [configuration guide](#gem-configuration-options) provides detailed instructions on the various available configurations.

Get the client_id and api_key for interacting with the JISC publications router web (from the JISC publications router portal)

```
client_id = "my_client_id"
api_key = "my_api_key"
```
You'll want to add an initializer in your rails application to configure the JISC publications router client to your needs:

```
# config/initializers/jisc_publications_router.rb
JiscPublicationsRouter.configure do |config|
    config.client_id = client_id
    config.api_key = api_key
    config.notifications_dir = "notifications"
end
```

### In ruby code / from the console

Require the gem in the rails console

```
require "jisc_publications_router"
```

Check the configuration options supplied in the initializer are registered

```
JiscPublicationsRouter.configuration
```

**Get list of notifications**

```
nl = JiscPublicationsRouter::V4::NotificationsList.new
response_body, notification_ids, since_id = nl.get_notifications_list(since: "2023-01-01", save_response: true)
```

This method gets one page of notifications. The default page size in the JISC publications router api is 25 (maximum is 100).

Each notification is looped over, and the following actions are performed

* Metadata is saved to disk
* The list of contents are extracted into a file called `content_links.json`
* The contents to be retrieved are added to a `notification_content` queue
* After the contents have been successfully fetched, the `notification id` and `notification path` is added to the `notification` queue, as explained in the workers below.

**Get list of all notifications**

```
nl = JiscPublicationsRouter::V4::NotificationsList.new
all_notification_ids = nl.get_all_notifications(save_response: true)
```

This method calls `Get list of notifications` recursively

* Starting from the last id retrieved in the previous run or from "1970-01-01"
* It retrieves either all notifications or a maximum of 10,000 calls are made (25 per page - 250,000 notifications are retrieved).

**Get notification**

```
n = JiscPublicationsRouter::V4::Notification.new
response_body = n.get_notification('1494732')
```

This method is used to get the notification for one particular id. 

After the notification metadata is retrieved, the following actions are perfromed

* Metadata is saved to disk
* The list of contents are extracted into a file called `content_links.json`
* The contents to be retrieved are added to a `notification_content` queue
* After the contents have been successfully fetched, the `notification id` and `notification path` is added to the `notification` queue, as explained in the workers below.

**To check Sidekiq queue**

```
# queues used are notification and notification_content
q = Sidekiq::Queue.new('notification')
q.size
q.each do |job|
  puts job.klass, job.args, job.jid
end
```

### From the rake task

**Get list of all notifications**

The rake task is used to get all notifications since the last run. It calls `get all notifications` described above.

You will need to add an initializer in your rails application to configure the JISC publications router client before calling the rake task.

```
rake 'jisc_publications_router:get_all_notifications
```

If you also want the responses saved in the notifications directory, use the argument `--save_response` or `--sr` .  This argument is optional.

```
rake 'jisc_publications_router:get_all_notifications -- --save_response'
```
or
```
rake 'jisc_publications_router:get_all_notifications -- --sr'
```


## Gem configuration options

`client_id` : 

* The client_id for the JISC publications router API to get list of matching notifications
* Required

`api_key` : 

* The api_key to to authorise connections to the JISC publications router
* Required

`notifications_dir` :

* The directory used by the gem to store data from the API calls 

* Required

* The files stored in the directory are

  * `.since` : File used to store the last id retrieved from the notifications API. This is then read in the next run of the API

    ```
    notifications/
    └── .since
    ```

  * list of notifications in a pair tree of depth 2 (if chosen to save notifications using file adapter)

    ```
    notifications/
    ├── 13
    │   ├── 75
    │   │   ├── 1375589
    │   │   │   ├── content_links.json
    │   │   │   └── notification.json
    │   │   └── 1375918
    │   │       ├── content_links.json
    │   │       └── notification.json
    │   └── 99
    │       ├── 1399093
    │       │   ├── content_links.json
    │       │   └── notification.json
    ├── 14
    │   ├── 00
    │   │   ├── 1400088
    │   │   │   └── notification.json
    ├── 15
    │   ├── 00
    │   │   ├── 1500020
    │   │   │   └── notification.json
    │   │   ├── 1500111
    │   │   │   ├── content_links.json
    │   │   │   └── notification.json
    ```

  * The response_body from get list of notifications list (if chosen to save response body using file adapter)

    ```
    notifications/
    ├── response_body
    │   ├── 2023-12-07_04-49-23.json
    │   ├── 2023-12-07_04-49-24.json
    ```

  * The content for each notification, stored within the directory for each notification,  in a pair tree of depth 2 (as shown above)

`api_endpoint` : 

* The API endpoint of the JISC publications router 
* Optional. The default value is `"https://pubrouter.jisc.ac.uk/api/v4"`

`retry_count` :

* The number of times to retry to attempt to retrieve a list of notifications
* Optional. The default value is `3`

`preferred_packaging_format` :

* The preferred packaging format for downloading content. 
* Optional. The default value is `"http://purl.org/net/sword/package/SimpleZip"`. The options are `"http://purl.org/net/sword/package/SimpleZip"` and `"https://pubrouter.jisc.ac.uk/FilesAndJATS"`
* The content matching this format will be downloaded and saved in the notification directory. 

`retrieve_unpackaged` : 

* Parameter to indicate if unpackaged content files are to be retrieved from JISC publications router
* Optional. The default value is `false`. 
* If set to true the unpackaged pdf files and unpakaged other files will be downloaded and saved in the notification directory.

`retrieve_content` :

* Parameter to indicate if the content files need to be downloaded.
* Optional. The default value is `false`. 
* If set to true 
  * The contents to be retrieved are added to a `notification_content` queue
  * After the contents have been successfully fetched, the `notification id` and `notification path` is added to the `notification` queue, as explained in the workers below.

`log_file` :

* Parameter to pass the name of the log file along with the path. 
* Optional. The default value is `log/jisc_publications_router.log`. 

`redis_url` :

* Parameter to pass the URL for redis.
* Optional. The default value is read from the environment variable `REDIS_URL`. If this is not set, the URL will default to `redis://localhost:6379/0`

`redis_password` :

* Parameter to pass the password for redis, if used.
* Optional. The default value is read from the environment variable `REDIS_PASSWORD`. If this is not set, it will default to an empty string.

## Workers used by the gem

### Notification content worker

For each notification retrieved from the JISC publications router API, (using either the list of notifications or the call for an individual notification), the gem will gather the list of contents and add them to the notification content worker (`JiscPublicationsRouter::Worker::NotificationContentWorker`).

* When made available, the list of content downloaded for each notification are:

  * The content of your preferred format (JATS or simple zip)

  * Full text from the publisher

  * The unpackaged content if chosen

* The worker is configured to use the `notification_content` queue in Redis.

* The `NotificationContentWorker` will download the content and save it to the notifications directory. You can override this worker in your application, based on how you would like to handle the list of content for each notification, and the actions you would like performed. 

* Once successful, the notification is added to the `notification` queue in Redis.

### Notification worker

The notification worker (`JiscPublicationsRouter::Worker::NotificationWorker`) will receive the data for each notification, from the notification list, after the contents have been downloaded successfully.  

* The worker is configured to use the `notification` queue in Redis.


* The gem provides just the boiler plate for the Worker class

  ```
  def perform(json_notification); end
  ```

  You can override this worker in your application, based on how you would like to handle the data for each notification, and the actions you would like performed. 

### 
