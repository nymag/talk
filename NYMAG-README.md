# Talk NyMag Development Guide

# Overview

* Coral Talk is a third-party commenting application embedded on NYM pages
* A comment stream is a view of Coral Talk that shows a list of comments associated with a specific page
* The `coral-talk` component is responsible for embedding Talk comment streams

# Quickstart

These are instructions for getting a local Clay page up and running with a Coral Talk comment stream that is acting like you are a logged in user.

Warning: This is not for testing the full functionality of the coral-talk component or its contract with TammanyHall. For that, see the "Full Quickstart" section below.

1. In sites, run `npm run start-local`.
2. Navigate to a published test page. Talk comment streams only appear on published pages!
3. You can spoof a login by running this in the console:


```
DS.get('cookies').set('nymag_session_user_id', '1234567');
DS.get('cookies').set('nymag_session_user', 'foobar');
DS.get('cookies').set('nymag_session', 'baz');
```

You can spoof Talk credentials by setting the `nymag_talk` cookie to a JWT token (see example in "Login Overview" section above). You can go to [jwt.io](https://jwt.io/) to generate a token with different claims. (Note that `exp` claim reflects the JWT token's expiration date. The coral-talk cmpt diregards the token if the current time is above it.)

# Full Quickstart

These are instructions for getting Sites, Talk, and TammanyHall all up and running together. This involves creating a test user and spoofing aspects of the login process as they do not work automatically locally.

## Create test user in TammanyHall.

POST to `http://localhost:8080/account` like so:

```
{
  "username":"cperryk",
  "email":"cperryk@gmail.com",
  "firstname":"Chris",
  "lastname":"Kirk",
  "gender":"M",
  "password":"password1",
  "zip":"10023",
  "referer":"http://www.nymag.com"
}
```

## Verify User

Check the TammanyHall MySQL database to get the user ID of the created user.

`docker ps`

Make a note of the container ID of the MySQL container. Run the following:

1. `docker exec -it <containerId> mysql`
2. `use nym_membership`
3. `update nym_membership SET validated_p=1`

## (Optional) Import a user with an identical ID into Coral Talk:

Because of the `nymag-auth` Talk plugin, a user logged in via TammanyHall who leaves a comment will automatically trigger the creation of an equivalent user inside the Talk database.

But if you wanted to create a user there manually, you could log into the mongo database and create it.

`mongo localhost:27018`
`use admin` (or `talk`)

```
db.users.insert({
  id: 1000888,
  username: 'cperryk',
  lowercaseUsername: 'cperryk',
  provider: 'local'
}) 
```

## Spoof Client-side Login

In sites, disable redirection in the login service. Comment out the redirection from `global/js/login.js`

Open a test page with a `coral-talk` component on it.

Attempt to login. Once you hit the modal's "Log In", nothing will happen because the redirect has been disabled. However, a session ID will now be stored on the TammanyHall server.

Return to the TammanyHall mysql database and execute `select session_id from nym_user_sessions;`. Note the last session ID in the results.

Return to your browser and run the following commands in the console, filling in data where needed. These commands will essentially do what the redirect chain does on prod; set session data on the client.

`DS.get('cookie').set('nymag_session_user_id', <userId>);`
`DS.get('cookie').set('nymag_session', <sessionId>);`
`DS.get('cookie').set('nymag_session_user', <userName>);`

Refresh the page. Now, Coral Talk should automatically sign you in!

# Login Overview

1.  If a user is logged in, the `coral-talk` component generates JWT claims
based on the user's cookies. This is an object that includes claims about the user's username, email, etc. It looks like:

```
{
  "aud": "talk",
  "iss": "http://nymag.com/coral-talk",
  "exp": 999999999999999,
  "sub": "1234567",
  "usn": "foobar",
  "eml": "foobar@gmail.com"
}
```

2. This object is sent to TammanyHall, which returns a signed JWT that looks like:

```
eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJ0YWxrIiwiaXNzIjoiaHR0cDovL255bWFnLmNvbS9jb3JhbC10YWxrIiwiZXhwIjo5OTk5OTk5OTk5OTk5OTksInN1YiI6IjEyMzQ1NjciLCJ1c24iOiJmb29iYXIiLCJlbWwiOiJmb29iYXJAZ21haWwuY29tIn0.wlV-A2MWZTmSm07YoNSMj9Ak9TOoK7Q5oPR-3Ex4BVk
```

This actually has three parts delimited by `.`. The second part is simply the Base64Url encoded claims object, and the last part is TammanyHall's signature. To learn more about this token, read about JWT [here](https://jwt.io/introduction/).

3. The coral-talk component receives this token and passes it into the function that embeds the Talk comment stream, which in turn passes it to the Talk server.

4. The Talk server, which has the same secret as TammanyHall, signs the claims and ensures the resulting signature is the same signature as the one TammanyHall produced.

# The Great CORS headache

* Talk does not support CORS.
* Yet we must make requests to it from NyMag pages to retrieve comment count for the comments button.
* Therefore, we must mount Talk on a route of the same domain at which we're viewing Clay.
* However, Talk's comment streams don't work if `TALK_ROOT_URL` (an env var inside Talk) does not reflect the basepath that they're viewed at, i.e. the `src` of the `iframe` that contains the comment stream.

This means that locally Talk will not work on all domains at once; you must change `TALK_ROOT_URL` to reflect whatever domain you're testing on.

It also means that on production we have **synthetic responses** to "pretend" that `TALK_ROOT_URL` reflects the requested domain. [Here's an example](http://www.grubstreet.com/coral-talk/embed/stream?asset_url=http%3A%2F%2Fwww.grubstreet.com%2F_pages%2Fcjhaiwrmz00p25hyetvxrstxd%40published.html&initialWidth=612&childId=_0.4370014933228332&parentTitle=NYC%20Shames%20Lawyer%20Who%20Threatened%20to%20Call%20ICE%20on%20Employee&parentUrl=http%3A%2F%2Fwww.grubstreet.com%2F2018%2F05%2Fnyc-shames-lawyer-who-threatened-to-call-ice-on-employee.html%23comments) (view source).