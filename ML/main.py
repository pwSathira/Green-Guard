# Step 1: Imports
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.preprocessing import MinMaxScaler
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense, LSTM, Dropout
from tensorflow.keras.optimizers import Adam
from sklearn.model_selection import train_test_split
import warnings
warnings.filterwarnings("ignore", category=UserWarning)


from random import uniform


# Step 2: Load and Merge Training Scenarios
file_names = ['scenario1.csv', 'scenario2.csv', 'scenario3.csv', 'scenario4.csv', 'scenario5.csv']
df_list = [pd.read_csv(name) for name in file_names]
df = pd.concat(df_list, ignore_index=True)


# Step 3: Preprocessing
features = ['Moisture', 'Humidity', 'Watering']
target = ['PlantHealth']


scaler_X = MinMaxScaler()
scaler_y = MinMaxScaler()


X_scaled = scaler_X.fit_transform(df[features])
y_scaled = scaler_y.fit_transform(df[target])


# Step 4: Create Sequences
def create_sequences(X, y, seq_length=5):
    X_seq, y_seq = [], []
    for i in range(len(X) - seq_length):
        X_seq.append(X[i:i+seq_length])
        y_seq.append(y[i+seq_length])
    return np.array(X_seq), np.array(y_seq)


X_seq, y_seq = create_sequences(X_scaled, y_scaled)


# Step 5: Train/Test Split
X_train, X_test, y_train, y_test = train_test_split(X_seq, y_seq, test_size=0.2, shuffle=False)


# Step 6: Build Model
model = Sequential([
    LSTM(64, input_shape=(X_seq.shape[1], X_seq.shape[2]), return_sequences=False),
    Dropout(0.2),
    Dense(32, activation='relu'),
    Dense(1)
])
model.compile(optimizer=Adam(learning_rate=0.001), loss='mse')
model.summary()


# Step 7: Train Model
model.fit(X_train, y_train, validation_data=(X_test, y_test), epochs=40, batch_size=16)


# Step 8: Manual Test Sequence (like a mini CSV)
test_input_df = pd.DataFrame([
# Input consists of whatever input is available of the current plant history. Small example input is below, replace with the current history
   [1, 65, 80, 0.6, 0.70],
  ], columns=['Day', 'Moisture', 'Humidity', 'Watering', 'PlantHealth'])


# Extract relevant features
test_input_raw = test_input_df[['Moisture', 'Humidity', 'Watering']].values
test_input_scaled = scaler_X.transform(test_input_raw)
test_input_seq = np.array([test_input_scaled])  # shape: (1, 6, 3)


# Step 9: Predict Health for this scenario
predicted_health = model.predict(test_input_seq)[0][0]
predicted_health_inv = scaler_y.inverse_transform([[predicted_health]])[0][0]


#print(f"\n📈 Predicted Plant Health Score Based on Your Sequence: {predicted_health_inv:.2f}")


import warnings
warnings.filterwarnings("ignore", category=UserWarning)


from itertools import product


# Step 10: Random Search for Best Moisture, Humidity, and Watering
num_samples = 100  # Try only 100 random combinations


best_score = -np.inf
best_input = None


for _ in range(num_samples):
    m = uniform(50, 70)
    h = uniform(55, 75)
    w = uniform(0.0, 1.0)


    candidate = np.array([[m, h, w]])
    candidate_scaled = scaler_X.transform(candidate)


    simulated_seq = np.vstack([test_input_scaled[1:], candidate_scaled])
    simulated_seq = simulated_seq.reshape(1, simulated_seq.shape[0], simulated_seq.shape[1])


    pred_scaled = model.predict(simulated_seq, verbose=0)[0][0]


    if pred_scaled > best_score:
        best_score = pred_scaled
        best_input = candidate[0]


# Inverse-transform predicted score
best_health = scaler_y.inverse_transform([[best_score]])[0][0]


# Print result
# Print result with scaled values
print(f"\n🌿 Optimized Recommendation Based on Your Trend:")
print(f"✅ Suggested Moisture: {best_input[0]:.2f}")
print(f"✅ Suggested Humidity: {best_input[1]:.2f}")
print(f"✅ Suggested Watering: {best_input[2]:.2f}")
print(f"📊 Expected Health Score: {best_health:.2f}")
