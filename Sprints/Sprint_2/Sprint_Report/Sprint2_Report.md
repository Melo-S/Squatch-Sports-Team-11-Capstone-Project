# Sprint 2 Report (Feb 23, 2026 – Mar 8, 2026)

## YouTube link of Sprint 2 Video (Make this video unlisted)
* TODO: Paste unlisted YouTube link here

## What's New (User Facing)
* Polished the main dashboard so it feels more like a real app instead of a placeholder screen
* Added working pages for History, Analytics, Goals, and Settings
* Added a shared workout/session data flow so stats update across multiple screens
* Made Form Shooting, Free Throws, and Spot Shooting usable drills
* Added drill detail flow so users can open a drill and start it from the drill page
* Added workout session saving so completed drill sessions now appear in History and affect Analytics
* Added structured Spot Shooting drill information, including court spots and shots per spot, to support future court-position features

## Work Summary (Developer Facing)
In Sprint 2, the team focused on making the app feel more connected and usable instead of just being a basic prototype. A lot of the work went into improving the iPhone-side experience, building out more complete screens, and making the drill flow work more smoothly from selection to workout tracking. The team also worked through setup issues, merge problems, and project configuration issues while continuing to build on the watch and phone connection. One important thing learned this sprint was that once workout data started being shared across multiple screens, changes in one part of the app affected several other parts, so keeping the app structure organized became much more important. Overall, Sprint 2 helped move the project from a rough demo into something that feels much closer to a real product.

## Unfinished Work
* Some drills are still not fully implemented yet, including Catch & Shoot, Off the Dribble, Midrange Series, 3PT Series, and Finishing.
* We need to implement persistent data storage. Sprint 2 made strong progress toward this, but the workout data is still not fully connected to persistent storage yet and will be finished in Sprint 3.

## Completed Issues/User Stories
Here are links to the issues that we completed in this sprint:
* https://github.com/KellamA/Squatch-Sports-Team-11-Capstone-Project/issues/10
* https://github.com/KellamA/Squatch-Sports-Team-11-Capstone-Project/issues/11
* https://github.com/KellamA/Squatch-Sports-Team-11-Capstone-Project/issues/9
* https://github.com/KellamA/Squatch-Sports-Team-11-Capstone-Project/issues/7

## Incomplete Issues/User Stories
Here are links to issues we worked on but did not complete in this sprint:
* https://github.com/KellamA/Squatch-Sports-Team-11-Capstone-Project/issues/13
  * We wanted to port drills from the existing app. Three were fully working by the end of Sprint 2, and the remaining drills will be finished in Sprint 3.
* https://github.com/KellamA/Squatch-Sports-Team-11-Capstone-Project/issues/12
  * This is extended functionality from the requirements. During free workouts, the user should be able to select where they are standing on the court so shot location can be tracked more accurately.
* https://github.com/KellamA/Squatch-Sports-Team-11-Capstone-Project/issues/14
  * Workouts are currently saved in memory, but they are not persistent once the app closes. Most of the setup is done, and this will be connected to persistent storage in the next sprint.

## Code Files for Review
Please review the following code files, which were actively developed during this sprint, for quality:
* DashboardHomeView.swift
* DrillsHomeView.swift
* iPhoneWorkoutView.swift

## Retrospective Summary

### Here's what went well:
* The team made good progress turning the app from a basic prototype into something more connected and usable, especially by improving the dashboard, drill flow, and shared workout data across multiple screens.
* The app is around 70–80% complete, so the project is making solid progress and is currently ahead of schedule.

### Here's what we'd like to improve:
* The main thing to improve is finishing the remaining requirements and continuing to polish the UI and overall user experience.

### Here are changes we plan to implement in the next sprint:
* In the next sprint, we plan to continue building out more drills and improve advanced features like court position support.
* Clean up the general UI and overall user experience.
