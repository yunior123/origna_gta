1. the search filter is kinda missing functionality: ex: when typing the word heavy it shows a list of products but when tapping u dont see anything, also, when typing u dont see any product card either
2. sometimes there is a kinda white background and the letters are kinda white so u cannot see properly, ex: login view in web, search others too
3. google sign in not working
4. sometimes in form fields the background is grey and the letter kinda white, u can barely see in there
5. if u hit the arrow back when in login view from the browser when going back then the page closes instead of going back to home view
6. add more products to dev.orignagta.ca for testing, there should be about 2000 so that we can test filters for every category or subcategory, scrolling, loading products on demand, etc.
7. now that we dont have the limitations of single page app of firebase we can now handle privacy policy and terms of service without html right? instead of opening a new tab we can handle it with the routes right?
8. right now it shows: impossible de charger les avis. is that an error?. Also: in dev make sure to populate some products with avis and also questions and answers.
9. update tasks.json , settings.json, launch.json
10. update hooks, all in .claude
11. update skills, agents in .claude .make sure to search anthropic docs for best practices and best github repos
12. make sure no magic strings
13. update repo map
14. update docs
15. solve bugs, clear BUGS.md when done
16. in mobile web view the product card details only shows some buttons but no image
17. stripe webhooks failing, we need to update them, use stripe cli for it
18. go view by view, widget by widget and ensure that we have semantics so that we can identify the elements in playwright tests, document all that. improve the playwright tests to include all of them, make sure that the coverage is 90+ . run all tests and fix as needed, make sure there is complete instructions.md on how to run the tests and all is needed. is it possible to autogenerate the semantic label and info to avoid having to explore the repo for semantics?. create a new skill for playwright before starting, search the web if needed in order to create the best skill, use the knowledge from learned.md if needed.
19. run all widget tests and fix as needed, the same for unit tests