import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestRegressor
from sklearn.tree import DecisionTreeRegressor
from sklearn.svm import SVR
from sklearn.metrics import mean_absolute_error, mean_squared_error
from xgboost import XGBRegressor
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import LSTM, Dense
import warnings
warnings.filterwarnings('ignore')
 
from preprocess import load_and_preprocess
 
df = load_and_preprocess()
 
# BASELINE feature set: only cycle history (matches existing papers)
baseline_features = ['Cycle Length', 'Period Length']
X = df[baseline_features]
y = df['Target_Next_Cycle_Length']
 
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
 
results = []
 
def evaluate(name, y_true, y_pred):
    mae = mean_absolute_error(y_true, y_pred)
    rmse = np.sqrt(mean_squared_error(y_true, y_pred))
    accuracy_within_2days = np.mean(np.abs(y_true - y_pred) <= 2) * 100
    results.append({"Model": name, "MAE": round(mae,2), "RMSE": round(rmse,2), "Accuracy(+/-2days)%": round(accuracy_within_2days,2)})
    print(f"{name}: MAE={mae:.2f}, RMSE={rmse:.2f}, Accuracy(+/-2days)={accuracy_within_2days:.2f}%")
 
# 1. Random Forest
rf = RandomForestRegressor(n_estimators=100, random_state=42)
rf.fit(X_train, y_train)
evaluate("Random Forest (baseline)", y_test, rf.predict(X_test))
 
# 2. XGBoost
xgb = XGBRegressor(n_estimators=100, random_state=42)
xgb.fit(X_train, y_train)
evaluate("XGBoost (baseline)", y_test, xgb.predict(X_test))
 
# 3. Decision Tree
dt = DecisionTreeRegressor(max_depth=5, random_state=42)
dt.fit(X_train, y_train)
evaluate("Decision Tree (baseline)", y_test, dt.predict(X_test))
 
# 4. SVM
svr = SVR(kernel='rbf')
svr.fit(X_train, y_train)
evaluate("SVM (baseline)", y_test, svr.predict(X_test))
 
# 5. LSTM (needs 3D input: samples, timesteps, features)
X_train_lstm = X_train.values.reshape((X_train.shape[0], 1, X_train.shape[1]))
X_test_lstm = X_test.values.reshape((X_test.shape[0], 1, X_test.shape[1]))
 
lstm_model = Sequential([
    LSTM(32, input_shape=(1, X_train.shape[1])),
    Dense(16, activation='relu'),
    Dense(1)
])
lstm_model.compile(optimizer='adam', loss='mse')
lstm_model.fit(X_train_lstm, y_train, epochs=50, batch_size=8, verbose=0)
lstm_pred = lstm_model.predict(X_test_lstm).flatten()
evaluate("LSTM (baseline)", y_test, lstm_pred)
 
# Save comparison table
results_df = pd.DataFrame(results)
results_df.to_csv('results_comparison.csv', index=False)
print("\nSaved results_comparison.csv")
print(results_df)