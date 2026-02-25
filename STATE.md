# STATE.md

_No pending issues._

1. There's a Cloud Run quota issue: "Could not create Cloud Run service get-seller-warehouses. Quota exceeded for quota metric 'Write
   requests' and limit 'Write requests per minute per region'"

  This is a deployment quota issue - the previous function deployment hit the Cloud Run write requests per minute quota. This means the
   functions weren't fully deployed!

  2. Also there's an old service being deleted from `us-central1` (wrong region) which is also hitting quota.

  But these are deployment logs. Let me look at actual function execution logs (not deployment):

3. make sure to mega seed firebase dev for admin, so that if Yunior uses admin user to login and manually qa test the app, he should be able to see all views functionals with data to provide feedback about ui

4. generate playwright flows in origna_flows and make sure to include instructions.md, claude.md all flutter semantics label, etc and enough context so that ai can audit the tests and add more as needed. before doing that u have to add semantics all over flutter app and gather all that data of semantics when generating origna_flows. The instructions should include auditing and creating new tests, the ai should give full new tests files if needed and not covered by existing tests.

5. everytime playwright tests are executed, save screen shots of the different views to desktop so that Yunior can see the views and give feedback related to ui ux and logic, etc. You can also read those images and fix what ever thing is blocking the tests