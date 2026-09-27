
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
    "GOOGLE_PLACES_API_KEY"
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
# PREDICTION ENDPOINT
# ============================================================

@app.route('/predict/<user_id>', methods=['POST'])
def predict(user_id):

    """
    Make a menstrual cycle prediction based on user health profile.

    Required:
        cycle_length
        period_length
        age
        bmi
        stress_level
        last_period_date

    Optional:
        exercise_frequency
        sleep_hours
        diet
        pcos
    """

    try:

        data = request.get_json()

        if not data:

            return jsonify({

                'error': 'No data provided',

                'status': 'incomplete_profile',

                'message':
                    'Please complete your health profile'

            }), 400


        print(
            f'Prediction request received for user: {user_id}'
        )

        print(
            f'Prediction profile: {data}'
        )


        # ======================================================
        # EXTRACT AND VALIDATE REQUIRED FIELDS
        # ======================================================

        cycle_length = get_int(
            data,
            'cycle_length'
        )

        period_length = get_int(
            data,
            'period_length'
        )

        age = get_int(
            data,
            'age'
        )

        bmi = get_number(
            data,
            'bmi'
        )


        # 0 is a valid stress value.
        stress_level = get_int(
            data,
            'stress_level'
        )

        if stress_level is None:

            stress_level = get_int(
                data,
                'stress'
            )


        # ======================================================
        # VALIDATION
        # ======================================================

        missing_fields = []


        if cycle_length is None:

            missing_fields.append(
                'cycle_length'
            )


        if age is None:

            missing_fields.append(
                'age'
            )


        if period_length is None:

            missing_fields.append(
                'period_length'
            )


        if bmi is None:

            missing_fields.append(
                'bmi'
            )


        if stress_level is None:

            missing_fields.append(
                'stress_level'
            )


        # ======================================================
        # LAST PERIOD DATE
        # ======================================================

        last_period_date = data.get(
            'last_period_date'
        )


        if not is_valid_date_string(
            last_period_date
        ):

            missing_fields.append(
                'last_period_date'
            )


        # ======================================================
        # RETURN INCOMPLETE PROFILE
        # ======================================================

        if missing_fields:

            print(
                f'Missing prediction data: {missing_fields}'
            )

            return jsonify({

                'status':
                    'incomplete_profile',

                'missing_fields':
                    missing_fields,

                'message':
                    'Please complete your profile. '
                    f'Missing: {", ".join(missing_fields)}',

                'prediction':
                    None,

                'next_period':
                    None,

                'fertile_window':
                    None,

                'confidence':
                    0

            }), 400


        # ======================================================
        # OPTIONAL FIELDS
        # ======================================================

        exercise_frequency = encode_exercise(
            data.get(
                'exercise_frequency',
                'moderate'
            )
        )

        if exercise_frequency is None:

            exercise_frequency = 1


        sleep_hours = get_number(
            data,
            'sleep_hours',
            7
        )


        diet = encode_diet(
            data.get(
                'diet',
                'low carb'
            )
        )

        if diet is None:

            diet = 0


        pcos = get_int(
            data,
            'pcos',
            0
        )


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


        print(
            f'Features: {features}'
        )

        print(
            f'Feature order: {FEATURE_ORDER}'
        )


        # ======================================================
        # MAKE ML PREDICTION
        # ======================================================

        if model is None:

            return jsonify({

                'error':
                    'ML model not available',

                'status':
                    'server_error'

            }), 500


        try:

            df = pd.DataFrame(

                [features],

                columns=FEATURE_ORDER

            )


            print(
                f'Model input DataFrame:\n{df}'
            )

            print(
                f'Model type: {type(model).__name__}'
            )


            raw_prediction = model.predict(
                df
            )[0]


        except Exception as e:

            print(
                f'Prediction error: {e}'
            )

            return jsonify({

                'error':
                    'Failed to make prediction',

                'message':
                    str(e),

                'status':
                    'prediction_error'

            }), 500


        # ======================================================
        # CONFIDENCE
        # ======================================================

        try:

            if hasattr(
                model,
                'predict_proba'
            ):

                confidence = (
                    float(
                        model.predict_proba(
                            df
                        )[0].max()
                    ) * 100
                )

            else:

                # Regression models such as DecisionTreeRegressor
                # do not have predict_proba().
                confidence = 75.0

        except Exception as e:

            print(
                f'Confidence calculation error: {e}'
            )

            confidence = 75.0


        # ======================================================
        # KEEP PREDICTED CYCLE IN REASONABLE RANGE
        # ======================================================

        predicted_days = int(
            round(
                float(
                    raw_prediction
                )
            )
        )


        predicted_days = max(
            15,
            min(
                predicted_days,
                45
            )
        )


        print(
            f'Raw ML prediction: {raw_prediction}'
        )

        print(
            f'Final predicted cycle length: {predicted_days}'
        )


        # ======================================================
        # CALCULATE CYCLE DATES
        # ======================================================

        last_period = datetime.fromisoformat(

            str(
                last_period_date
            ).replace(
                'Z',
                '+00:00'
            )

        )


        # Convert timezone-aware datetime to naive datetime.
        if last_period.tzinfo is not None:

            last_period = (
                last_period
                .astimezone(tz=None)
                .replace(tzinfo=None)
            )


        # ======================================================
        # NEXT PERIOD
        # ======================================================

        next_period = (
            last_period
            + timedelta(
                days=predicted_days
            )
        )


        # ======================================================
        # OVULATION
        # ======================================================

        ovulation = (
            next_period
            - timedelta(
                days=14
            )
        )


        # ======================================================
        # FERTILE WINDOW
        # ======================================================

        fertile_start = (
            ovulation
            - timedelta(
                days=5
            )
        )


        fertile_end = ovulation


        # ======================================================
        # CURRENT CYCLE DAY
        # ======================================================

        cycle_day_at_prediction = (

            datetime.now()
            - last_period

        ).days + 1


        if cycle_day_at_prediction < 1:

            cycle_day_at_prediction = 1


        # ======================================================
        # CYCLE PROGRESS
        # ======================================================

        cycle_progress = (

            cycle_day_at_prediction
            / predicted_days

        )


        cycle_progress = max(
            0.0,
            min(
                cycle_progress,
                1.0
            )
        )


        # ======================================================
        # CYCLE PHASE
        # ======================================================

        if cycle_day_at_prediction <= period_length:

            phase_label = 'Menstrual Phase'

        elif cycle_day_at_prediction < (
            predicted_days - 14
        ):

            phase_label = 'Follicular Phase'

        else:

            phase_label = 'Luteal Phase'


        # ======================================================
        # PCOS STATUS
        # ======================================================

        if pcos == 1:

            pcos_status = 'Reported PCOS'

        else:

            pcos_status = 'No PCOS reported'


        # ======================================================
        # MODEL FEATURE IMPORTANCE
        # ======================================================

        factor_weights = (
            get_model_feature_importance()
        )


        # ======================================================
        # RETURN SUCCESSFUL RESPONSE
        # ======================================================

        return jsonify({

            'status':
                'success',

            # --------------------------------------------------
            # ML PREDICTION
            # --------------------------------------------------

            'prediction':
                predicted_days,

            'predicted_cycle_length':
                predicted_days,


            # --------------------------------------------------
            # NEXT PERIOD
            # --------------------------------------------------

            'next_period':
                next_period.date().isoformat(),

            'next_period_label':
                next_period.strftime(
                    '%d/%m/%Y'
                ),


            # --------------------------------------------------
            # OVULATION
            # --------------------------------------------------

            'ovulation_date':
                ovulation.date().isoformat(),


            # --------------------------------------------------
            # FERTILE WINDOW
            # --------------------------------------------------

            'fertile_window': {

                'start':
                    fertile_start.date().isoformat(),

                'end':
                    fertile_end.date().isoformat()

            },

            'fertile_window_label': (

                f"{fertile_start.strftime('%d/%m/%Y')}"
                f" - "
                f"{fertile_end.strftime('%d/%m/%Y')}"

            ),


            # --------------------------------------------------
            # AI / MODEL CONFIDENCE
            # --------------------------------------------------

            'confidence':
                round(
                    confidence,
                    2
                ),


            # --------------------------------------------------
            # CURRENT CYCLE
            # --------------------------------------------------

            'current_day':
                cycle_day_at_prediction,

            'cycle_day_at_prediction':
                cycle_day_at_prediction,


            # --------------------------------------------------
            # PHASE
            # --------------------------------------------------

            'phase_label':
                phase_label,


            # --------------------------------------------------
            # CYCLE PROGRESS
            # --------------------------------------------------

            'cycle_progress':
                cycle_progress,


            # --------------------------------------------------
            # MODEL FACTOR WEIGHTS
            # --------------------------------------------------

            'factor_weights':
                factor_weights,


            # --------------------------------------------------
            # PCOS
            # --------------------------------------------------

            'pcos_risk':
                pcos_status,


            # --------------------------------------------------
            # PROFILE / CYCLE INFORMATION
            # --------------------------------------------------

            'avg_cycle_length':
                cycle_length,

            'avg_period_length':
                period_length,

            'cycle_length_history': [
                cycle_length
            ]

        }), 200


    except Exception as e:

        print(
            f'Unexpected error in /predict: {e}'
        )

        return jsonify({

            'error':
                'Unexpected server error',

            'message':
                str(e)

        }), 500


# ============================================================
# FIND DOCTORS ENDPOINT
# ============================================================

# ============================================================
# FIND NEARBY DOCTORS / HOSPITALS / CLINICS
# GOOGLE PLACES API (NEW)
# ============================================================

@app.route('/find-doctors', methods=['POST'])
def find_doctors():

    try:
        data = request.get_json(silent=True) or {}

        latitude = data.get('latitude')
        longitude = data.get('longitude')
        radius = data.get('radius', 5000)

        print("==============================================")
        print("DOCTOR FINDER REQUEST")
        print(f"Latitude: {latitude}")
        print(f"Longitude: {longitude}")
        print(f"Radius: {radius}")
        print("==============================================")

        # --------------------------------------------------------
        # VALIDATE LOCATION
        # --------------------------------------------------------

        if latitude is None or longitude is None:
            return jsonify({
                'error': 'Latitude and longitude are required.'
            }), 400

        try:
            latitude = float(latitude)
            longitude = float(longitude)
            radius = int(radius)
        except (TypeError, ValueError):
            return jsonify({
                'error': 'Invalid latitude, longitude or radius.'
            }), 400

        if not (-90 <= latitude <= 90):
            return jsonify({
                'error': 'Invalid latitude.'
            }), 400

        if not (-180 <= longitude <= 180):
            return jsonify({
                'error': 'Invalid longitude.'
            }), 400

        # Keep radius within Google's practical range
        radius = max(100, min(radius, 50000))

        # --------------------------------------------------------
        # GOOGLE API KEY
        # --------------------------------------------------------

        google_api_key = os.environ.get(
            'GOOGLE_PLACES_API_KEY'
        )

        if not google_api_key:
            print(
                "ERROR: GOOGLE_PLACES_API_KEY is missing."
            )

            return jsonify({
                'error':
                    'Google Places API key is not configured '
                    'on the server.'
            }), 500

        # --------------------------------------------------------
        # GOOGLE PLACES API (NEW)
        # --------------------------------------------------------

        url = (
            'https://places.googleapis.com/v1/places:searchNearby'
        )

        headers = {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': google_api_key,
            'X-Goog-FieldMask': (
                'places.id,'
                'places.displayName,'
                'places.location,'
                'places.formattedAddress,'
                'places.rating,'
                'places.currentOpeningHours'
            ),
        }

        # Search valid medical facility types.
        #
        # We make separate requests so that if one category
        # fails, the other categories can still work.

        search_types = [
            'doctor',
            'hospital',
            'medical_clinic',
        ]

        all_facilities = []

        for search_type in search_types:

            print(
                f"Searching Google Places for: "
                f"{search_type}"
            )

            payload = {
                'includedTypes': [
                    search_type
                ],
                'maxResultCount': 20,
                'locationRestriction': {
                    'circle': {
                        'center': {
                            'latitude': latitude,
                            'longitude': longitude,
                        },
                        'radius': float(radius),
                    }
                },
            }

            try:
                google_response = requests.post(
                    url,
                    headers=headers,
                    json=payload,
                    timeout=20,
                )

                print(
                    f"Google response for "
                    f"{search_type}: "
                    f"{google_response.status_code}"
                )

                print(
                    f"Google body for "
                    f"{search_type}: "
                    f"{google_response.text[:2000]}"
                )

            except requests.RequestException as e:

                print(
                    f"Google request failed for "
                    f"{search_type}: {e}"
                )

                continue

            # ----------------------------------------------------
            # HANDLE GOOGLE ERROR
            # ----------------------------------------------------

            if google_response.status_code != 200:

                print(
                    f"Google Places error for "
                    f"{search_type}: "
                    f"{google_response.text}"
                )

                continue

            try:
                google_data = google_response.json()
            except ValueError:

                print(
                    f"Invalid JSON from Google for "
                    f"{search_type}"
                )

                continue

            # ----------------------------------------------------
            # READ PLACES
            # ----------------------------------------------------

            places = google_data.get(
                'places',
                []
            )

            print(
                f"Google returned "
                f"{len(places)} places for "
                f"{search_type}"
            )

            for place in places:

                place_id = place.get('id')

                display_name = place.get(
                    'displayName',
                    {}
                )

                name = display_name.get(
                    'text',
                    'Unknown'
                )

                location = place.get(
                    'location',
                    {}
                )

                place_latitude = location.get(
                    'latitude'
                )

                place_longitude = location.get(
                    'longitude'
                )

                if (
                    not place_id
                    or place_latitude is None
                    or place_longitude is None
                ):
                    continue

                opening_hours = place.get(
                    'currentOpeningHours'
                )

                is_open = None

                if isinstance(
                    opening_hours,
                    dict
                ):
                    is_open = opening_hours.get(
                        'openNow'
                    )

                facility = {
                    'id': str(place_id),

                    'name': str(name),

                    'latitude': float(
                        place_latitude
                    ),

                    'longitude': float(
                        place_longitude
                    ),

                    'address': place.get(
                        'formattedAddress'
                    ),

                    'type': search_type,

                    'rating': place.get(
                        'rating'
                    ),

                    'is_open': is_open,
                }

                all_facilities.append(
                    facility
                )

        # --------------------------------------------------------
        # REMOVE DUPLICATES
        # --------------------------------------------------------

        unique_facilities = {}

        for facility in all_facilities:

            facility_id = facility.get('id')

            if facility_id:
                unique_facilities[
                    facility_id
                ] = facility

        facilities = list(
            unique_facilities.values()
        )

        # --------------------------------------------------------
        # SORT BY RATING
        # --------------------------------------------------------

        facilities.sort(
            key=lambda x: (
                x.get('rating') or 0
            ),
            reverse=True,
        )

        facilities = facilities[:30]

        print("==============================================")
        print(
            f"TOTAL UNIQUE FACILITIES: "
            f"{len(facilities)}"
        )

        for facility in facilities[:10]:
            print(
                facility.get('name'),
                facility.get('latitude'),
                facility.get('longitude'),
                facility.get('type'),
            )

        print("==============================================")

        return jsonify({
            'success': True,
            'facilities': facilities,
            'count': len(facilities),
        }), 200

    except Exception as e:

        print(
            "=============================================="
        )

        print(
            f"DOCTOR FINDER SERVER ERROR: {e}"
        )

        print(
            "=============================================="
        )

        return jsonify({
            'error':
                'Doctor finder server error.',
            'details': str(e),
        }), 500

# ============================================================
# GET DOCTOR DETAILS
# GOOGLE PLACES API (NEW)
# ============================================================

@app.route(
    '/find-doctors/<path:place_id>',
    methods=['GET']
)
def get_doctor_details(place_id):

    try:

        google_api_key = os.environ.get(
            'GOOGLE_PLACES_API_KEY'
        )

        if not google_api_key:

            return jsonify({
                'error':
                    'Google Places API key is not configured.'
            }), 500

        print("==============================================")
        print("DOCTOR DETAILS REQUEST")
        print(f"Place ID: {place_id}")
        print("==============================================")

        # Google Places API (New) uses:
        # GET /v1/places/{place_id}

        # The search endpoint returns IDs such as:
        # places/ChIJxxxxxxxx
        #
        # If only the final ID is supplied, add "places/".

        if not place_id.startswith('places/'):

            place_resource = f'places/{place_id}'

        else:

            place_resource = place_id

        url = (
            'https://places.googleapis.com/v1/'
            f'{place_resource}'
        )

        headers = {
            'X-Goog-Api-Key': google_api_key,

            'X-Goog-FieldMask': (
                'id,'
                'displayName,'
                'formattedAddress,'
                'nationalPhoneNumber,'
                'internationalPhoneNumber,'
                'websiteUri,'
                'rating,'
                'currentOpeningHours,'
                'reviews'
            ),
        }

        response = requests.get(
            url,
            headers=headers,
            timeout=20
        )

        print(
            f"Google Details Response: "
            f"{response.status_code}"
        )

        print(
            f"Google Details Body: "
            f"{response.text[:3000]}"
        )

        if response.status_code != 200:

            return jsonify({

                'error':
                    'Could not get facility details.',

                'details':
                    response.text

            }), response.status_code

        place = response.json()

        display_name = place.get(
            'displayName',
            {}
        )

        opening_hours = place.get(
            'currentOpeningHours'
        )

        is_open = None

        if isinstance(
            opening_hours,
            dict
        ):

            is_open = opening_hours.get(
                'openNow'
            )

        details = {

            'address':
                place.get(
                    'formattedAddress'
                ),

            'phone':
                place.get(
                    'nationalPhoneNumber'
                    or
                    'internationalPhoneNumber'
                ),

            'website':
                place.get(
                    'websiteUri'
                ),

            'opening_hours':
                opening_hours,

            'rating':
                place.get(
                    'rating'
                ),

            'reviews':
                place.get(
                    'reviews',
                    []
                )[:5]

        }

        return jsonify({

            'status':
                'success',

            'name':
                display_name.get(
                    'text'
                ),

            'details':
                details

        }), 200

    except Exception as e:

        print(
            f'Error getting doctor details: {e}'
        )

        return jsonify({

            'error':
                'Failed to get doctor details',

            'message':
                str(e)

        }), 500


# ============================================================
# LOG SYMPTOMS ENDPOINT
# ============================================================

@app.route(
    '/log/<user_id>',
    methods=['POST']
)
def log_symptoms(user_id):

    """
    Log symptoms for a user.
    """

    try:

        data = request.get_json()


        print(
            f'Symptoms logged for user: {user_id}'
        )

        print(
            f'Data: {data}'
        )


        return jsonify({

            'status':
                'success',

            'message':
                'Symptoms logged successfully'

        }), 200


    except Exception as e:

        print(
            f'Error logging symptoms: {e}'
        )

        return jsonify({

            'error':
                'Failed to log symptoms',

            'message':
                str(e)

        }), 500


# ============================================================
# CHAT ENDPOINT - ASHA AI
# ============================================================

@app.route(
    '/chat',
    methods=['POST']
)
def chat():

    """
    Chat with Asha AI.
    """

    try:

        data = request.get_json()


        message = data.get(
            'message'
        )

        history = data.get(
            'history',
            []
        )


        if not message:

            return jsonify({

                'error':
                    'No message provided',

                'status':
                    'invalid_request'

            }), 400


        if not client:

            return jsonify({

                'error':
                    'AI service not available',

                'status':
                    'service_unavailable'

            }), 503


        # ======================================================
        # BUILD CONVERSATION
        # ======================================================

        messages = [

            {
                'role':
                    'system',

                'content':
                    SYSTEM_PROMPT

            }

        ]


        for item in history:

            messages.append({

                'role':
                    item.get(
                        'role',
                        'user'
                    ),

                'content':
                    item.get(
                        'content',
                        ''
                    )

            })


        messages.append({

            'role':
                'user',

            'content':
                message

        })


        # ======================================================
        # GET AI RESPONSE
        # ======================================================

        response = client.messages.create(

            model=AI_MODELS[0],

            max_tokens=1000,

            messages=messages

        )


        reply = response.content[0].text


        return jsonify({

            'status':
                'success',

            'reply':
                reply

        }), 200


    except Exception as e:

        print(
            f'Error in chat: {e}'
        )

        return jsonify({

            'error':
                'Failed to process chat',

            'message':
                str(e),

            'status':
                'server_error'

        }), 500


# ============================================================
# ERROR HANDLERS
# ============================================================

@app.errorhandler(404)
def not_found(error):

    return jsonify({

        'error':
            'Endpoint not found',

        'status':
            'not_found'

    }), 404


@app.errorhandler(500)
def internal_error(error):

    return jsonify({

        'error':
            'Internal server error',

        'status':
            'server_error'

    }), 500


# ============================================================
# MAIN
# ============================================================

if __name__ == '__main__':

    app.run(
        debug=False,
        host='0.0.0.0',
        port=10000
    )

