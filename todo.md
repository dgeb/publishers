* we don't want to lose the uphold token, even if eyeshade is down
  * we can use a background job to send (and retry sending) the token to eyeshade
    * are we concerned that sidekiq might lose the job?
    * should we also store the token in publisher until the background job completes?

* are there any failure scenarios for uphold auth that we need to account for?
  * we only associated a success URI, so probably not

Vector
1. state token is stored in a session cookie
2. state token is passed to uphold
3. uphold redirects back to publishers passing state token 
4. session cookie is also sent with redirect
5. publishers compares state token to session[state token] which was also in the request
     a hacker could craft a redirect request with the state token and session of choice and 
     publishers has no way of verifying
     