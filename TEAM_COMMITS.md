# Suggested genuine team work / commit sequence

**Important:** This archive is a shared starting implementation. Do not fabricate
past commit dates, split one copied upload into meaningless commits, or attribute
code to a teammate who did not actually author or review it. Each person must
make and commit real changes themselves, with meaningful messages and evidence.

## Akshitha — UI, navigation, insights, integration (20 real milestones)
1. Scaffold Flutter app and document requirements
2. Configure app theme and typography
3. Build bottom navigation shell
4. Add dashboard budget card
5. Add recent transaction list
6. Add empty dashboard state
7. Build transaction form layout
8. Add amount and required-field validation
9. Add date and payment controls
10. Build transaction detail screen
11. Add detail edit navigation
12. Add delete confirmation UI
13. Build history screen layout
14. Add category filter chips
15. Add month navigation
16. Add totals and aggregate cards
17. Add chart and chart labels
18. Improve accessibility and screen-reader labels
19. Add widget tests and fix UI bugs
20. Review integration, run two-device UI tests, document evidence

## Mouni — database, persistence, helper, challenge (20 real milestones)
1. Define category and transaction models
2. Define SQLite schema and foreign keys
3. Seed default categories
4. Implement category create/read operations
5. Implement category update/delete restriction
6. Implement transaction create/read operations
7. Implement transaction update/delete
8. Add repository error handling
9. Add shared state controller
10. Add local budget persistence
11. Add reminder preference persistence
12. Add challenge model and table
13. Implement challenge start/progress
14. Implement challenge finish/reset
15. Implement challenge deletion
16. Implement spending helper rules
17. Add baseline and edge-case tests
18. Document held-out helper evaluation
19. Test restart/offline persistence and database integrity
20. Review integration, fix bugs, document architecture and test evidence

These are **possible future commits**, not a claim that any of them occurred.
You should revise ownership to reflect actual work and preserve individual
GitHub authorship, ClickUp task links, tests, and PR reviews.

## Branch commands (run by each teammate on their own computer)
```bash
git clone https://github.com/MouniSri039/PennyPilot.git
cd PennyPilot
git checkout -b feature/your-specific-feature
# edit and test the relevant files
git add .
git commit -m "feat: describe the actual change"
git push -u origin feature/your-specific-feature
```
Open a pull request, ask the other teammate to review, then merge.
