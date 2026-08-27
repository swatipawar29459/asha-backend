import pandas as pd
from sklearn.preprocessing import LabelEncoder
 
def load_and_preprocess():
    df = pd.read_csv("C:/Users/pawar/OneDrive/Dokumen/Menstrual_Cycle_Prediction/dataset/menstrual_cycle_dataset_with_fact.csv")
 
    # Convert dates
    df['Cycle Start Date'] = pd.to_datetime(df['Cycle Start Date'])
    df['Next Cycle Start Date'] = pd.to_datetime(df['Next Cycle Start Date'])
 
    # Sort so "next cycle length" can be computed per user
    df = df.sort_values(['User ID', 'Cycle Start Date'])
 
    # Target: the length of the NEXT cycle (shift within each user group)
    df['Target_Next_Cycle_Length'] = df.groupby('User ID')['Cycle Length'].shift(-1)
 
    # Drop last row per user (no "next" cycle to predict)
    df = df.dropna(subset=['Target_Next_Cycle_Length'])
 
    # Encode categorical columns
    le_exercise = LabelEncoder()
    le_diet = LabelEncoder()
    le_symptoms = LabelEncoder()
 
    df['Exercise Frequency'] = le_exercise.fit_transform(df['Exercise Frequency'])
    df['Diet'] = le_diet.fit_transform(df['Diet'])
    df['Symptoms'] = le_symptoms.fit_transform(df['Symptoms'])
 
    return df
 
if __name__ == "__main__":
    df = load_and_preprocess()
    print(df.head())
    print("Shape after preprocessing:", df.shape)