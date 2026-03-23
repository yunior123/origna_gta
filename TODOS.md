1. run all live tests in backend and frontend. fix as needed. dont stop till done
2. run e2e tests in orignabase rust and origna_gta. fix as needed.dont stop till done
3. improve mega seed dev db in vps with more than 2000 products, all of them with some sample image. 2.make sure to seed db for all variants and states so that we can see all views with non empty state: ex: favorites view with favorited products ex1:seller dashboard full ex2:admin dashboard full ex3:addresses etc, all, search the missing gaps
4. coverage for orignabase rust and origna_gta should be 95+ for tests. increase coverage, test all. priority for live tests, unit tests are secondary.fix all warnings too
5. always clean cargo garbage to avoid using too much space, the same for flutter.
6. run all example apps tests and clean after done
7. make sure there are no loose ends left. if u have blokers add them to state.md
10. when running tests always point the results to temp file to avoid losing test results
11. fix warnings
12. do these, no excuses: tests skipped (live tests - need backend), tests failed (expected - backend connection issues)
13. no skipping, implement instead
14. everything claude code github repo study how to apply to improve our repo
15. run load tests, reliability tests, stress tests, benchmarks, example apps and tests
16. audit webhook stripe endpoints: stripe vs orignabase. all webhooks:test and live using cli
17. use delegation to document codebase like pro, search web for best practices. document so well that it will avoid going back and forth many times: ex: we were using for loop for images compression then future.wait then for loop again
18. audit full codebase with 30+ agents, use delegation. findings should be added to state.md. findings should be validated in depth to avoid false positives.
19. audit auth system
20. improve local host test configuration and test system for stripe cli webhook forwarding, orignabase, meilisearch,flutter
21. use delegation to document codebase like pro, search web for best practices. document so well that it will avoid going back and forth many times: ex: we were using for loop for images compression then future.wait then for loop again. document functions, clases, etc
