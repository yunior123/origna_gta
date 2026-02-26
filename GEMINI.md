# Gemini Project Instructions

This project follows the rules and conventions defined in [CLAUDE.md](./CLAUDE.md). 
CLAUDE.md is the absolute source of truth for project-wide mandates, engineering standards, and architectural patterns.

## Interaction Principles
- Adhere strictly to the "Chain of Verification" and "Logic First" principles.
- Prioritize high-signal, concise output.
- Follow the MVVM + Riverpod architecture.
- Ensure all code complies with Canadian and international laws.
- No legacy code handling – we fix forward.

Refer to `CLAUDE.md` for the full list of rules and technical specifications.

## RULES
1. CHAIN OF VERIFICATION: First answer the question. Second, list at least 3 ways your answer could be wrong. Third, verify your concern and update your answer. 
2. Using the word legacy is forbidden, no legacy code in app since its new and the launch is in 10-25 days
3. website for production is www.orignagta.ca Note: .com is not used for now
4. Forbidden to defer or skip task
5. Make sure that all code comply with canadian and international laws
6. use as many team agents and agents as needed to solve the issues.
7. If playwright tests or cloud functions deployement take too long ex 1h, it means that something is wrong. So we stop and analyze what went wrong to start over if needed and fix it.
8. env , env.local , etc and service account keys cannot be deployed to cloud functions
9. you are supposed to do all the work, using tools like stripe cli, gcloud cli, firebase cli, mcp connections, etc. Avoid asking Yunior for manual setup, he is a solo developer so he is too busy reviewing code. all tools are your disposal can be freely used, Yunior trust you, that is why he gave you full tool access.
10. on every deploy of indexes, rules, functions, hosting make sure to deploy to dev, staging and prod.
11. everytime playwright tests are executed, save screen shots of the different views to desktop so that Yunior can see the views and give feedback related to ui ux and logic, etc.
12. running playwright tests and fixing should be really fast, take screenshot of the tests while they are running then analyze them to see what is wrong and fix it.
13. there are many mcp, cli tools that you can use, dont be shy. You can use them all without Yunior permission, he has already given you authorization.
14. when given an audit with suggested fixes to implement make sure that is backed by evidence, the suggestions can be implemented by first we need to gather the all agents in the .claude/agents and see if there are better alternatives or we can just implement the fix in the suggested way.
15. did you finish answering a question, then now,  search the web, github, reddit- the social media, stackoverflow, etc and try to improve a bit the suggested fixes, bonus, etc, add different ways of solving them for the ones that might have different ways. make sure that you answer like a pro.
16. if you fix an issue make sure that it works for dev, staging and prod.
17. make sure there is no code in app that updates legacy code or fields in the db from the past, register that in the brain, you are managing backward compatibility and as a result the code is messy, dont do that shit please, we launch within a few weeks, db is empty, we fix now
18. this is so bad, really terrible, the app has not launched yet and your are having into consideration legacy code that leads to confusion, no legacy handling in the code, if you add a new feature you never have into consideration backward compatibility since we have not lanuched yet. Listen to me, never, never, never do that, put it really deep into your brain. When exploring the code always fix all code that has into account older, deprecated, legacy things. 
19. **Logic first** — 50+ adversarial scenarios, predict and architect like Magnus Carlsen. Think: malicious seller, buyer, race conditions.
20. **Future proof app** — app schema design has to be future proof and scale to 100M+ users. The schema has to be designed to support scale and prevent having to update app schema in the future, so it has to be bullet proof and conceived by the best architect and masterminds like Magnus Carlsen. We need to build an app that will not require migrations in the future. We can use the rival agent to have an idea on how the big e-commerce companies have structured their apps, not just the schema, the whole architecture is important. No backward compatibility needed since the production database is empty, the app has not launched yet. Now is the time to do preventing fixes to avoid having to migrate in the future. The UX has to be amazing, specially when showing errors to users. Catching errors in backend and frontend is super important for receiving feedback and autofixing.
21. **Save tokens** — show only actions and results, save Yunior's money as much as possible, he is your friend and a nice person that does not want to go bankrupt. Avoid large sessions that consume too many tokens, propose new sessions with tasks indications to continue from there with another agent.
22. **"save"/"remember"** → persist to `.claude/LEARNED.md`
23. **Match Yunior's language-respond in whichever language he uses, ask him questions when needed, ask him whether tasks should be deffered before taking action, if you need access to an specific mcp you just need to ask him, do not skip mcp connections just because u dont have access to them, simply ask Yunior. U can use chrome claude extension, playwright, apple password manager and any other tool at your disposal to get access to my personal account in websites if mcp is not supported for those, do not limit yourself, lets get the best results together. If u need access to any tool just ask Yunior** 
24. **No new markdown files** unless asked
25. **Cross-stack check and traslations on new created texts** after every edit — Python ↔ Dart ↔ Schema 
26. **No magic strings** — use constants from schema_constants. No hardcoded values.
27. **Changing one line → update EVERY file that line impacts** (Tests, Rules, Indexes, Schema, playwright tests, etc)
28. **Bonus fixes are appreciated, suggetions can be added to state.md, claude.md must be updated on every session initialization** 
29. ** 🤖 Specialized Agent Playbooks, when taking decision or applying or verifying that the issues and bonus features or issues are correct, spawn them all to verify that the answer is correct so that all is well orchestrated.
30. if you add new features, make sure to add tests for that feature
31. The code and logic have to be bullet proof, like a pro
32. typing is super important
33. the whole architecture of the app is super important, all flows have to be bulletproof and logicproof. 
---

Now I have a full picture. Let me compile the findings and produce fixed files.Now I have the complete picture. Here's my full audit with all fixes:

---
