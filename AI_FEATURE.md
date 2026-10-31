# PennyPilot — Offline Spending Check Evaluation

## 1. Purpose and User Control

We developed an offline Spending Check feature to help users understand how their monthly expenses compare with their budget.

We implemented this feature using rule-based logic rather than a trained machine-learning model. It works entirely offline and does not require an external API or internet connection.

Our goal was to provide simple, understandable spending suggestions while keeping users in control of their financial decisions. Users can choose whether to follow the suggestions.

## 2. How We Implemented It

We implemented the Spending Check in `lib/services/spending_helper.dart`.

We calculate monthly spending using expense transactions from the selected calendar month. We exclude income transactions and expenses from other months.

We defined three main spending conditions:

- **Below 80% of the budget:** We show a message indicating that spending is within the budget.
- **From 80% to below 100%:** We notify users that they are approaching their budget limit.
- **At or above 100%:** We warn users that they have reached or exceeded their budget.

We also handle invalid budgets. If the budget is zero or negative, we ask the user to set a valid budget.

We kept the messages simple so users can understand why they received a particular suggestion.

## 3. How We Evaluated the Feature

To evaluate our Spending Check, we compared it with a basic baseline.

Our baseline always displays the same message:

“Review your expenses regularly.”

Unlike our Spending Check, the baseline does not consider how much of the budget has been used.

We created five held-out test cases in `test/spending_helper_held_out_evaluation_test.dart`.

We selected examples representing normal spending, spending close to the budget limit, and spending above the limit.

| Test case | Amount spent | Budget | Budget used | Expected result | Our helper | Baseline |
|---|---:|---:|---:|---|---|---|
| H1 | $125 | $500 | 25% | On track | Correct | Incorrect |
| H2 | $395 | $500 | 79% | On track | Correct | Incorrect |
| H3 | $401 | $500 | 80.2% | Approaching limit | Correct | Incorrect |
| H4 | $490 | $500 | 98% | Approaching limit | Correct | Incorrect |
| H5 | $525 | $500 | 105% | Limit reached | Correct | Incorrect |

## 4. Our Evaluation Results

Our Spending Check correctly classified all five held-out test cases.

- **Our Spending Check:** 5 out of 5 correct (100%).
- **Baseline:** 0 out of 5 correct (0%).

These results show that our rule-based approach correctly handled the five spending situations we tested.

However, we understand that five examples are not enough to prove that the feature will always provide useful financial advice.

We also completed our final application verification:

- **153 automated tests passed.**
- **80.28% code coverage achieved.**
- **Zero Flutter static analysis issues.**
- **Android release APK built successfully.**

We kept our test and coverage evidence separately so the results can be reviewed.

## 5. Limitations We Identified

During our evaluation, we identified some limitations in our approach.

For example, suppose a student makes a large tuition payment or has an unexpected medical expense.

Our Spending Check might warn that the monthly budget has been exceeded, even though the expense was necessary.

This happens because our helper only considers the amount spent compared with the budget.

It does not understand personal circumstances, future income, emergencies, or whether a particular expense is essential.

We also recognize that our current implementation does not predict future spending or learn from previous transactions.

## 6. What We Would Improve

If we continue developing PennyPilot, we would like to improve the Spending Check by allowing users to dismiss certain warnings or identify exceptional expenses.

For example, users could mark an expense as necessary so the application can provide more appropriate feedback.

We would also add new tests to verify that these improvements work correctly.

For this project, we decided to keep the helper rule-based because it is easy to explain, test, and maintain.

## 7. Offline Functionality and Reproducibility

We designed the Spending Check to work without internet access.

All calculations and recommendations are generated locally using the available financial records.

We can reproduce our five-case evaluation using:

`flutter test test/spending_helper_held_out_evaluation_test.dart`

Our automated tests verify the helper's behavior. A separate two-device airplane-mode and restart demonstration has not yet been documented in this report.

## 8. Conclusion

Through this feature, we learned how to turn financial data into simple, useful recommendations.

We also learned the importance of comparing our implementation against a baseline, testing different scenarios, and recognizing the limitations of our approach.

Although our Spending Check is not a trained AI model, we believe its rule-based approach is suitable for the current version of PennyPilot because it is transparent, predictable, and works offline.

**Team Members:** Akshitha Sainath Sanagarapu and Mouni Sri Nallapaneni.
