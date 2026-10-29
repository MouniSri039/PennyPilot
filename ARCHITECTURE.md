# Architecture

Flutter UI -> Provider/ChangeNotifier (`FinanceState`) -> SQLite repository
(`FinanceDatabase`) -> local `pennypilot.db`.

`BudgetCategory` (1) -> (many) `MoneyTransaction` through `category_id`.
Both support create, list, edit, and delete. Deleting a category with linked
transactions is blocked by an explicit count check and SQLite foreign key
restriction; users must move/delete child transactions first.

`SavingsChallenge` is a third SQLite entity with persistent start, progress,
finish, reset, and delete actions. Settings are stored with SharedPreferences.

Five screen roles: Dashboard, Transaction Form, Transaction Detail,
History/Insights, and Settings. Category and challenge screens are auxiliary.

The reminder switch stores a preference only; OS notifications are NOT scheduled
in this starter implementation. CSV export and advanced animations are NOT built.
