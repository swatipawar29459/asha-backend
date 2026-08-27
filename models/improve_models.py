import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.tree import DecisionTreeRegressor
from sklearn.metrics import mean_absolute_error, mean_squared_error
from scipy.stats import wilcoxon
import joblib

from preprocess import load_and_preprocess

df = load_and_preprocess()
y = df['Target_Next_Cycle_Length']

# ---------- BASELINE: cycle history only ----------
baseline_features = ['Cycle Length', 'Period Length']
X_base = df[baseline_features]
X_train_b, X_test_b, y_train, y_test = train_test_split(X_base, y, test_size=0.2, random_state=42)

baseline_model = DecisionTreeRegressor(max_depth=5, random_state=42)
baseline_model.fit(X_train_b, y_train)
baseline_pred = baseline_model.predict(X_test_b)

baseline_mae = mean_absolute_error(y_test, baseline_pred)
baseline_acc = np.mean(np.abs(y_test - baseline_pred) <= 2) * 100

# ---------- IMPROVED: + lifestyle/health features ----------
improved_features = ['Cycle Length', 'Period Length', 'Age', 'BMI',
                      'Stress Level', 'Exercise Frequency', 'Sleep Hours',
                      'Diet', 'PCOS']
X_imp = df[improved_features]
X_train_i, X_test_i, y_train_i, y_test_i = train_test_split(X_imp, y, test_size=0.2, random_state=42)

improved_model = DecisionTreeRegressor(max_depth=8, min_samples_split=5, random_state=42)
improved_model.fit(X_train_i, y_train_i)
improved_pred = improved_model.predict(X_test_i)

improved_mae = mean_absolute_error(y_test_i, improved_pred)
improved_acc = np.mean(np.abs(y_test_i - improved_pred) <= 2) * 100

# ---------- Print comparison ----------
print(f"BASELINE  -> MAE={baseline_mae:.2f}, Accuracy(+/-2days)={baseline_acc:.2f}%")
print(f"IMPROVED  -> MAE={improved_mae:.2f}, Accuracy(+/-2days)={improved_acc:.2f}%")

# ---------- Paired test: which is actually better ----------
baseline_errors = np.abs(y_test.values - baseline_pred)
improved_errors = np.abs(y_test_i.values - improved_pred)

stat, p_value = wilcoxon(baseline_errors, improved_errors)
print(f"\nPaired Wilcoxon test p-value: {p_value:.5f}")

if p_value < 0.05:
    winner = "IMPROVED" if improved_mae < baseline_mae else "BASELINE"
    print(f"Result: statistically significant difference -> {winner} model is better")
else:
    print("Result: no statistically significant difference between the two")

# ---------- Save the best model ----------
if improved_mae < baseline_mae:
    joblib.dump(improved_model, 'final_model.pkl')
    print("\nImproved model saved as final_model.pkl")
else:
    joblib.dump(baseline_model, 'final_model.pkl')
    print("\nBaseline model saved as final_model.pkl")