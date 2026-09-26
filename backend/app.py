from flask import Flask, jsonify, request
from flask_cors import CORS
import joblib
import pandas as pd
import requests
import os
import re
from openai import OpenAI
from dotenv import load_dotenv
from datetime import datetime, timedelta


# ============================================================
# LOAD ENVIRONMENT VARIABLES
# ============================================================

BASE_DIR = os.path.dirname(
    os.path.abspath(__file__)
)

load_dotenv(
    os.path.join(
        BASE_DIR,
        ".env"
    )
)


# ============================================================
# FLASK SETUP
# ============================================================

app = Flask(__name__)

CORS(app)


# ============================================================
# OPENROUTER / AI SETUP
# ============================================================

OPENROUTER_API_KEY = os.environ.get(
    "OPENROUTER_API_KEY"
)

client = None

if OPENROUTER_API_KEY:

    client = OpenAI(
        base_url="https://openrouter.ai/api/v1",
        api_key=OPENROUTER_API_KEY,
    )


# ============================================================
# GOOGLE PLACES API
# ============================================================

GOOGLE_PLACES_API_KEY = os.environ.get(
    'GOOGLE_PLACES_API_KEY'
)


# ============================================================
# AI MODELS
# ============================================================

AI_MODELS = [

    "openrouter/free",

    "google/gemma-4-31b-it:free",

    "google/gemma-4-26b-a4b-it:free",

    "qwen/qwen3.8-27b:free",

]


# ============================================================
# ASHA AI SYSTEM PROMPT
# ============================================================

SYSTEM_PROMPT = (
    "You are Asha, a warm and supportive women's menstrual "
    "wellness companion. "

    "You help users understand menstruation, menstrual cycles, "
    "periods, ovulation, PMS, common menstrual symptoms, "
    "reproductive wellness, self-care, and general women's "
    "health education. "

    "Respond naturally and conversationally. "

    "Use conversation history to understand what the user means. "

    "IMPORTANT: Return ONLY the final answer intended for the user. "
    "Do not reveal internal reasoning, chain-of-thought, hidden "
    "thoughts, analysis, deliberation, planning, or reasoning steps. "
    "Do not use <think> tags. Do not write sections such as "
    "'Thinking', 'Reasoning', or 'Analysis'. "

    "You are not a doctor and must never diagnose a medical "
    "condition. "

    "Do not claim certainty about a user's health. "

    "Give general educational and wellness information. "

    "If the user describes severe, persistent, unusual, or "
    "potentially dangerous symptoms, recommend consulting "
    "a qualified healthcare professional. "

    "Do not prescribe medication or provide medication dosages. "

    "Be warm, empathetic, clear, and easy to understand. "

    "Keep answers reasonably short unless the user asks for "
    "more detail. "

    "If a question is completely unrelated to women's health, "
    "politely explain that Asha is primarily designed for "
    "women's menstrual and wellness questions."
)


# ============================================================
# LOAD MACHINE LEARNING MODEL
# ============================================================

MODEL_PATH = os.path.join(
    BASE_DIR,
    "final_model.pkl"
)

try:

    model = joblib.load(
        MODEL_PATH
    )

    print(
        "ML model loaded successfully."
    )

except Exception as e:

    model = None

    print(
        "Could not load ML model:",
        e
    )


# ============================================================
# MODEL FEATURE ORDER
# ============================================================

FEATURE_ORDER = [

    "Cycle Length",
    "Period Length",
    "Age",
    "BMI",
    "Stress Level",
    "Exercise Frequency",
    "Sleep Hours",
    "Diet",
    "PCOS"

]


# ============================================================
# HELPER FUNCTIONS
# ============================================================

def get_number(
    data,
    key,
    default=None
):

    value = data.get(
        key,
        default
    )

    if value is None:
        return default

    try:

        return float(
            value
        )

    except (
        TypeError,
        ValueError
    ):

        return default


def get_int(
    data,
    key,
    default=None
):

    value = data.get(
        key,
        default
    )

    if value is None:
        return default

    try:

        return int(
            float(value)
        )

    except (
        TypeError,
        ValueError
    ):

        return default


def encode_exercise(
    value
):

    if value is None:
        return None

    if isinstance(
        value,
        (int, float)
    ):

        return int(
            value
        )

    value = str(
        value
    ).strip().lower()

    mapping = {

        "low": 0,
        "moderate": 1,
        "high": 2

    }

    return mapping.get(
        value
    )


def encode_diet(
    value
):

    if value is None:
        return None

    if isinstance(
        value,
        (int, float)
    ):

        return int(
            value
        )

    value = str(
        value
    ).strip().lower()

    mapping = {

        "low carb": 0,
        "balanced": 1,
        "vegetarian": 2,
        "high protein": 3

    }

    return mapping.get(
        value
    )


def is_valid_date_string(
    value
):

    if not value:
        return False

    try:

        datetime.fromisoformat(
            str(value).replace(
                "Z",
                "+00:00"
            )
        )

        return True

    except Exception:

        return False


# ============================================================
# MODEL FEATURE IMPORTANCE
# ============================================================

def get_model_feature_importance():

    importance = {}

    try:

        if model is None:
            return importance

        values = getattr(
            model,
            "feature_importances_",
            None
        )

        if values is None:
            return importance

        if len(values) != len(
            FEATURE_ORDER
        ):

            print(
                "Feature importance length does not match "
                "FEATURE_ORDER."
            )

            return importance

        for index, feature in enumerate(
            FEATURE_ORDER
        ):

            importance[feature] = round(
                float(
                    values[index]
                ),
                4
            )

        return importance

    except Exception as e:

        print(
            f"Error getting feature importance: {e}"
        )

        return importance


# ============================================================
# ROOT ROUTE
# ============================================================

@app.route('/', methods=['GET'])
def root():
    return jsonify({
        'status': 'success',
        'message': 'Asha backend is running'
    }), 200


# ============================================================
# PREDICTION ENDPOINT - UPDATED WITH VALIDATION
# ============================================================

@app.route('/predict/<user_id>', methods=['POST'])
def predict(user_id):
    """
    Make a menstrual cycle prediction based on user health profile.
    Requires: cycle_length, period_length, age, bmi, stress_level, last_period_date
    Optional: exercise_frequency, sleep_hours, diet, pcos
    """
    
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({
                'error': 'No data provided',
                'status': 'incomplete_profile',
                'message': 'Please complete your health profile'
            }), 400
        
        print(f'Prediction request received for user: {user_id}')
        print(f'Prediction profile: {data}')
        
        # ======================================================
        # EXTRACT AND VALIDATE REQUIRED FIELDS
        # ======================================================
        
        cycle_length = get_int(data, 'cycle_length', 28)
        period_length = get_int(data, 'period_length')
        age = get_int(data, 'age')
        bmi = get_number(data, 'bmi')
        stress_level = get_int(data, 'stress_level') or get_int(data, 'stress')
        
        # ======================================================
        # VALIDATION: Check for required fields
        # ======================================================
        
        missing_fields = []
        
        if age is None:
            missing_fields.append('age')
        if period_length is None:
            missing_fields.append('period_length')
        if bmi is None:
            missing_fields.append('bmi')
        if stress_level is None:
            missing_fields.append('stress_level')
        
        # Check for last_period_date
        last_period_date = data.get('last_period_date')
        if not is_valid_date_string(last_period_date):
            missing_fields.append('last_period_date')
        
        # ======================================================
        # IF MISSING REQUIRED FIELDS: Return error with missing fields
        # ======================================================
        
        if missing_fields:
            print(f'Missing prediction data: {missing_fields}')
            return jsonify({
                'status': 'incomplete_profile',
                'missing_fields': missing_fields,
                'message': f'Please complete your profile. Missing: {", ".join(missing_fields)}',
                'prediction': None,
                'next_period': None,
                'fertile_window': None,
                'confidence': 0
            }), 400
        
        # ======================================================
        # EXTRACT OPTIONAL FIELDS
        # ======================================================
        
        exercise_frequency = encode_exercise(
            data.get('exercise_frequency', 1)
        ) or 1
        
        sleep_hours = get_number(
            data, 'sleep_hours', 7
        )
        
        diet = encode_diet(
            data.get('diet', 'Low Carb')
        ) or 0
        
        pcos = get_int(data, 'pcos', 0)
        
        # ======================================================
        # PREPARE FEATURES FOR MODEL
        # ======================================================
        
        features = [
            cycle_length,
            period_length,
            age,
            bmi,
            stress_level,
            exercise_frequency,
            sleep_hours,
            diet,
            pcos
        ]
        
        print(f'Features: {features}')
        print(f'Feature order: {FEATURE_ORDER}')
        
        # ======================================================
        # MAKE PREDICTION
        # ======================================================
        
        if model is None:
            return jsonify({
                'error': 'ML model not available',
                'status': 'server_error'
            }), 500
        
        try:
            df = pd.DataFrame([features], columns=FEATURE_ORDER)
            prediction = model.predict(df)[0]
            confidence = model.predict_proba(df)[0].max() * 100 if hasattr(model, 'predict_proba') else 0
            
        except Exception as e:
            print(f'Prediction error: {e}')
            return jsonify({
                'error': 'Failed to make prediction',
                'message': str(e),
                'status': 'prediction_error'
            }), 500
        
        # ======================================================
        # CALCULATE CYCLE DATES
        # ======================================================
        
        last_period = datetime.fromisoformat(
            last_period_date.replace('Z', '+00:00')
        )
        
        next_period = last_period + timedelta(days=prediction)
        
        # Fertile window: 5 days before ovulation (14 days before next period)
        ovulation = next_period - timedelta(days=14)
        fertile_start = ovulation - timedelta(days=5)
        fertile_end = ovulation
        
        # ======================================================
        # RETURN SUCCESSFUL RESPONSE
        # ======================================================
        
        return jsonify({
            'status': 'success',
            'prediction': int(prediction),
            'next_period': next_period.isoformat(),
            'ovulation_date': ovulation.isoformat(),
            'fertile_window': {
                'start': fertile_start.isoformat(),
                'end': fertile_end.isoformat()
            },
            'confidence': round(confidence, 2),
            'cycle_day_at_prediction': (
                (datetime.now() - last_period).days + 1
            )
        }), 200
        
    except Exception as e:
        print(f'Unexpected error in /predict: {e}')
        return jsonify({
            'error': 'Unexpected server error',
            'message': str(e)
        }), 500


# ============================================================
# FIND DOCTORS ENDPOINT - NEW
# ============================================================

@app.route('/find-doctors', methods=['POST'])
def find_doctors():
    """
    Find nearby doctors, clinics, and hospitals using Google Places API.
    
    Expected request body:
    {
        "latitude": 19.0760,
        "longitude": 72.8777,
        "radius": 5000  // in meters (default: 5km)
    }
    """
    
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({
                'error': 'No location data provided',
                'status': 'invalid_request'
            }), 400
        
        latitude = data.get('latitude')
        longitude = data.get('longitude')
        radius = data.get('radius', 5000)  # Default 5km
        
        # ======================================================
        # VALIDATE COORDINATES
        # ======================================================
        
        if latitude is None or longitude is None:
            return jsonify({
                'error': 'Latitude and longitude are required',
                'status': 'invalid_coordinates'
            }), 400
        
        try:
            latitude = float(latitude)
            longitude = float(longitude)
            radius = int(radius)
        except (ValueError, TypeError):
            return jsonify({
                'error': 'Invalid coordinate values',
                'status': 'invalid_coordinates'
            }), 400
        
        # ======================================================
        # SEARCH FOR DOCTORS/HOSPITALS
        # ======================================================
        
        if not GOOGLE_PLACES_API_KEY:
            print('⚠️ GOOGLE_PLACES_API_KEY not configured')
            return jsonify({
                'error': 'Healthcare provider service not available',
                'status': 'service_unavailable',
                'facilities': []
            }), 503
        
        # Search parameters
        location = f"{latitude},{longitude}"
        search_types = [
            'doctor',
            'hospital',
            'health',
            'gynecologist'
        ]
        
        all_facilities = []
        
        for search_type in search_types:
            try:
                google_places_url = (
                    f"https://maps.googleapis.com/maps/api/place/nearbysearch/json"
                    f"?location={location}"
                    f"&radius={radius}"
                    f"&type={search_type}"
                    f"&key={GOOGLE_PLACES_API_KEY}"
                )
                
                response = requests.get(
                    google_places_url,
                    timeout=10
                )
                
                if response.status_code == 200:
                    results = response.json().get('results', [])
                    
                    for place in results:
                        facility = {
                            'id': place.get('place_id'),
                            'name': place.get('name'),
                            'latitude': place.get('geometry', {}).get('location', {}).get('lat'),
                            'longitude': place.get('geometry', {}).get('location', {}).get('lng'),
                            'address': place.get('vicinity'),
                            'type': search_type,
                            'rating': place.get('rating'),
                            'is_open': place.get('opening_hours', {}).get('open_now'),
                        }
                        all_facilities.append(facility)
                
            except requests.exceptions.Timeout:
                print(f'Timeout searching for {search_type}')
                continue
            except Exception as e:
                print(f'Error searching for {search_type}: {e}')
                continue
        
        # ======================================================
        # REMOVE DUPLICATES AND SORT BY RATING
        # ======================================================
        
        seen_ids = set()
        unique_facilities = []
        
        for facility in all_facilities:
            facility_id = facility['id']
            if facility_id not in seen_ids:
                seen_ids.add(facility_id)
                unique_facilities.append(facility)
        
        # Sort by rating (highest first)
        unique_facilities.sort(
            key=lambda x: x.get('rating') or 0,
            reverse=True
        )
        
        # ======================================================
        # RETURN RESULTS
        # ======================================================
        
        return jsonify({
            'status': 'success',
            'location': {
                'latitude': latitude,
                'longitude': longitude,
                'radius': radius
            },
            'facilities': unique_facilities[:20],  # Top 20 results
            'total_found': len(unique_facilities)
        }), 200
        
    except Exception as e:
        print(f'Error in /find-doctors: {e}')
        return jsonify({
            'error': 'Failed to find healthcare providers',
            'message': str(e),
            'status': 'server_error'
        }), 500


# ============================================================
# GET DOCTOR DETAILS ENDPOINT - NEW
# ============================================================

@app.route('/find-doctors/<place_id>', methods=['GET'])
def get_doctor_details(place_id):
    """
    Get detailed information about a specific healthcare facility.
    """
    
    if not GOOGLE_PLACES_API_KEY:
        return jsonify({
            'error': 'Service unavailable',
            'status': 'service_unavailable'
        }), 503
    
    try:
        url = (
            f"https://maps.googleapis.com/maps/api/place/details/json"
            f"?place_id={place_id}"
            f"&fields=formatted_address,formatted_phone_number,website,opening_hours,rating,reviews"
            f"&key={GOOGLE_PLACES_API_KEY}"
        )
        
        response = requests.get(url, timeout=10)
        
        if response.status_code == 200:
            result = response.json().get('result', {})
            
            return jsonify({
                'status': 'success',
                'details': {
                    'address': result.get('formatted_address'),
                    'phone': result.get('formatted_phone_number'),
                    'website': result.get('website'),
                    'opening_hours': result.get('opening_hours'),
                    'rating': result.get('rating'),
                    'reviews': result.get('reviews', [])[:5]  # Top 5 reviews
                }
            }), 200
        else:
            return jsonify({
                'error': 'Place not found',
                'status': 'not_found'
            }), 404
            
    except Exception as e:
        print(f'Error getting doctor details: {e}')
        return jsonify({
            'error': 'Failed to get details',
            'message': str(e)
        }), 500


# ============================================================
# LOG SYMPTOMS ENDPOINT
# ============================================================

@app.route('/log/<user_id>', methods=['POST'])
def log_symptoms(user_id):
    """Log symptoms for a user."""
    
    try:
        data = request.get_json()
        
        print(f'Symptoms logged for user: {user_id}')
        print(f'Data: {data}')
        
        return jsonify({
            'status': 'success',
            'message': 'Symptoms logged successfully'
        }), 200
        
    except Exception as e:
        print(f'Error logging symptoms: {e}')
        return jsonify({
            'error': 'Failed to log symptoms',
            'message': str(e)
        }), 500


# ============================================================
# CHAT ENDPOINT - ASHA AI
# ============================================================

@app.route('/chat', methods=['POST'])
def chat():
    """Chat with Asha AI."""
    
    try:
        data = request.get_json()
        
        message = data.get('message')
        history = data.get('history', [])
        
        if not message:
            return jsonify({
                'error': 'No message provided',
                'status': 'invalid_request'
            }), 400
        
        if not client:
            return jsonify({
                'error': 'AI service not available',
                'status': 'service_unavailable'
            }), 503
        
        # Build conversation
        messages = [
            {'role': 'system', 'content': SYSTEM_PROMPT}
        ]
        
        # Add history
        for item in history:
            messages.append({
                'role': item.get('role', 'user'),
                'content': item.get('content', '')
            })
        
        # Add current message
        messages.append({
            'role': 'user',
            'content': message
        })
        
        # Get response
        response = client.messages.create(
            model=AI_MODELS[0],
            max_tokens=1000,
            messages=messages
        )
        
        reply = response.content[0].text
        
        return jsonify({
            'status': 'success',
            'reply': reply
        }), 200
        
    except Exception as e:
        print(f'Error in chat: {e}')
        return jsonify({
            'error': 'Failed to process chat',
            'message': str(e)
        }), 500


# ============================================================
# ERROR HANDLERS
# ============================================================

@app.errorhandler(404)
def not_found(error):
    return jsonify({
        'error': 'Endpoint not found',
        'status': 'not_found'
    }), 404


@app.errorhandler(500)
def internal_error(error):
    return jsonify({
        'error': 'Internal server error',
        'status': 'server_error'
    }), 500


# ============================================================
# MAIN
# ============================================================

if __name__ == '__main__':
    app.run(debug=False, host='0.0.0.0', port=10000)