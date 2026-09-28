# ============================================================
# ASHA BACKEND
# ============================================================

from flask import Flask, jsonify, request
from flask_cors import CORS

import joblib
import pandas as pd
import requests
import os

from openai import OpenAI
from dotenv import load_dotenv
from datetime import datetime, timedelta


# ============================================================
# BASE DIRECTORY + ENVIRONMENT
# ============================================================

BASE_DIR = os.path.dirname(
    os.path.abspath(__file__)
)

load_dotenv(
    os.path.join(BASE_DIR, ".env")
)


# ============================================================
# FLASK SETUP
# ============================================================

app = Flask(__name__)

CORS(app)


# ============================================================
# API KEYS
# ============================================================

OPENROUTER_API_KEY = os.environ.get(
    "OPENROUTER_API_KEY"
)

GOOGLE_MAPS_API_KEY = os.environ.get(
    "GOOGLE_MAPS_API_KEY"
)


# ============================================================
# OPENROUTER / AI SETUP
# ============================================================

client = None

if OPENROUTER_API_KEY:

    client = OpenAI(
        base_url="https://openrouter.ai/api/v1",
        api_key=OPENROUTER_API_KEY,
    )

    print(
        "OpenRouter client initialized successfully."
    )

else:

    print(
        "WARNING: OPENROUTER_API_KEY not found."
    )


# ============================================================
# AI MODELS
# ============================================================

AI_PRIMARY_MODEL = "openrouter/free"

AI_FALLBACK_MODELS = [
    "openrouter/free",
    "google/gemma-4-31b-it:free",
    "qwen/qwen3.8-27b:free",
]


# ============================================================
# ASHA AI SYSTEM PROMPT
# ============================================================

SYSTEM_PROMPT = (

    "You are Asha, a warm and supportive women's "
    "menstrual wellness companion. "

    "You help users understand menstruation, menstrual "
    "cycles, periods, ovulation, PMS, common menstrual "
    "symptoms, reproductive wellness, self-care, and "
    "general women's health education. "

    "Respond naturally and conversationally. "

    "Use conversation history to understand what the "
    "user means. "

    "IMPORTANT: Return ONLY the final answer intended "
    "for the user. Do not reveal internal reasoning, "
    "chain-of-thought, hidden thoughts, analysis, "
    "deliberation, planning, or reasoning steps. "

    "Do not use <think> tags. "

    "Do not write sections such as 'Thinking', "
    "'Reasoning', or 'Analysis'. "

    "You are not a doctor and must never diagnose a "
    "medical condition. "

    "Do not claim certainty about a user's health. "

    "Give general educational and wellness information. "

    "If the user describes severe, persistent, unusual, "
    "or potentially dangerous symptoms, recommend "
    "consulting a qualified healthcare professional. "

    "Do not prescribe medication or provide medication "
    "dosages. "

    "Be warm, empathetic, clear, and easy to understand. "

    "Keep answers reasonably short unless the user asks "
    "for more detail. "

    "If a question is completely unrelated to women's "
    "health, politely explain that Asha is primarily "
    "designed for women's menstrual and wellness "
    "questions."
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

    "PCOS",

]


# ============================================================
# GOOGLE API URLS
# ============================================================

GOOGLE_PLACES_NEARBY_URL = (
    "https://places.googleapis.com/v1/places:searchNearby"
)

GOOGLE_PLACES_DETAILS_URL = (
    "https://places.googleapis.com/v1/places"
)

GOOGLE_GEOCODING_URL = (
    "https://geocode.googleapis.com/v4/geocode/address"
)


# ============================================================
# GOOGLE KEY STATUS
# ============================================================

if GOOGLE_MAPS_API_KEY:

    print(
        "Google Maps server API key loaded."
    )

else:

    print(
        "WARNING: GOOGLE_MAPS_API_KEY not found."
    )


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

        return float(value)

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


def encode_exercise(value):

    if value is None:
        return None

    if isinstance(
        value,
        (int, float)
    ):

        return int(value)

    value = str(
        value
    ).strip().lower()

    mapping = {

        "low": 0,

        "moderate": 1,

        "high": 2,

    }

    return mapping.get(
        value
    )


def encode_diet(value):

    if value is None:
        return None

    if isinstance(
        value,
        (int, float)
    ):

        return int(value)

    value = str(
        value
    ).strip().lower()

    mapping = {

        "low carb": 0,

        "balanced": 1,

        "vegetarian": 2,

        "high protein": 3,

    }

    return mapping.get(
        value
    )


def is_valid_date_string(value):

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
                "Feature importance length does not "
                "match FEATURE_ORDER."
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
            "Error getting feature importance:",
            e
        )

        return importance


def google_headers(
    field_mask
):

    return {

        "Content-Type":
            "application/json",

        "X-Goog-Api-Key":
            GOOGLE_MAPS_API_KEY,

        "X-Goog-FieldMask":
            field_mask,

    }


def google_error_message(
    response
):

    try:

        data = response.json()

        error = data.get(
            "error",
            {}
        )

        if isinstance(
            error,
            dict
        ):

            message = error.get(
                "message"
            )

            if message:
                return message

        return str(
            data
        )

    except Exception:

        return (
            response.text
            or
            "Unknown Google API error."
        )


def normalize_place_type(
    place
):

    primary_type = str(
        place.get(
            "primaryType",
            ""
        )
    ).lower()

    types = [

        str(item).lower()

        for item in place.get(
            "types",
            []
        )

    ]

    all_types = set(
        types
    )

    all_types.add(
        primary_type
    )

    if (
        "hospital" in all_types
        or
        "general_hospital" in all_types
    ):

        return "hospital"

    if (
        "medical_center" in all_types
        or
        "medical_clinic" in all_types
    ):

        return "clinic"

    if "doctor" in all_types:

        return "doctor"

    return "clinic"


# ============================================================
# ROOT
# ============================================================

@app.route(
    "/",
    methods=["GET"]
)
def root():

    return jsonify({

        "status":
            "success",

        "message":
            "Asha backend is running",

    }), 200


# ============================================================
# HEALTH CHECK
# ============================================================

@app.route(
    "/health",
    methods=["GET"]
)
def health():

    return jsonify({

        "status":
            "healthy",

        "model_loaded":
            model is not None,

        "google_maps_configured":
            bool(
                GOOGLE_MAPS_API_KEY
            ),

        "openrouter_configured":
            bool(
                OPENROUTER_API_KEY
            ),

    }), 200


# ============================================================
# PREDICTION ENDPOINT
# ============================================================

@app.route(
    "/predict/<user_id>",
    methods=["POST"]
)
def predict(user_id):

    try:

        data = request.get_json(
            silent=True
        )

        if not data:

            return jsonify({

                "status":
                    "error",

                "message":
                    "No user health profile data received.",

                "error":
                    "incomplete_profile"

            }), 400


        # ----------------------------------------------------
        # REQUIRED USER DATA
        # ----------------------------------------------------

        required_fields = [

            "age",

            "cycle_length",

            "period_length",

            "bmi",

            "last_period_date",

        ]


        missing = [

            field

            for field in required_fields

            if data.get(field) is None

        ]


        if missing:

            return jsonify({

                "status":
                    "error",

                "message":
                    "Required health profile data is missing.",

                "error":
                    "incomplete_profile",

                "missing_fields":
                    missing

            }), 400


        # ----------------------------------------------------
        # USER'S ACTUAL SAVED PROFILE DATA
        # ----------------------------------------------------

        cycle_length = get_int(
            data,
            "cycle_length"
        )

        period_length = get_int(
            data,
            "period_length"
        )

        age = get_int(
            data,
            "age"
        )

        bmi = get_number(
            data,
            "bmi"
        )

        stress_level = get_int(

            data,

            "stress_level",

            data.get(
                "stress",
                3
            )

        )

        exercise_frequency = get_int(

            data,

            "exercise_frequency",

            1

        )

        sleep_hours = get_number(

            data,

            "sleep_hours",

            7

        )

        diet = data.get(

            "diet",

            "Low Carb"

        )

        pcos = get_int(

            data,

            "pcos",

            0

        )

        last_period_date = data.get(

            "last_period_date"

        )


        # ----------------------------------------------------
        # VALIDATE BASIC CYCLE DATA
        # ----------------------------------------------------

        if cycle_length is None or cycle_length <= 0:

            return jsonify({

                "status":
                    "error",

                "message":
                    "Invalid cycle length.",

                "error":
                    "invalid_cycle_length"

            }), 400


        if period_length is None or period_length <= 0:

            return jsonify({

                "status":
                    "error",

                "message":
                    "Invalid period length.",

                "error":
                    "invalid_period_length"

            }), 400


        # ----------------------------------------------------
        # VALIDATE MODEL
        # ----------------------------------------------------

        if model is None:

            return jsonify({

                "status":
                    "error",

                "message":
                    "ML model is not loaded.",

                "error":
                    "model_not_loaded"

            }), 500


        # ----------------------------------------------------
        # CREATE ML FEATURES
        # ----------------------------------------------------

        features = pd.DataFrame([{

            "Cycle Length":
                cycle_length,

            "Period Length":
                period_length,

            "Age":
                age,

            "BMI":
                bmi,

            "Stress Level":
                stress_level,

            "Exercise Frequency":
                encode_exercise(
                    exercise_frequency
                ),

            "Sleep Hours":
                sleep_hours,

            "Diet":
                encode_diet(
                    diet
                ),

            "PCOS":
                pcos,

        }])


        print(
            "=============================================="
        )

        print(
            "PERSONALIZED ML PREDICTION"
        )

        print(
            f"User ID: {user_id}"
        )

        print(
            f"Cycle Length: {cycle_length}"
        )

        print(
            f"Period Length: {period_length}"
        )

        print(
            f"Age: {age}"
        )

        print(
            f"BMI: {bmi}"
        )

        print(
            f"Stress: {stress_level}"
        )

        print(
            f"Exercise: {exercise_frequency}"
        )

        print(
            f"Sleep: {sleep_hours}"
        )

        print(
            f"Diet: {diet}"
        )

        print(
            f"PCOS: {pcos}"
        )

        print(
            "=============================================="
        )


        # ----------------------------------------------------
        # ML PREDICTION
        #
        # This remains the actual ML output for the
        # research/project comparison.
        # ----------------------------------------------------

        predicted_days = float(

            model.predict(
                features
            )[0]

        )

        predicted_days = round(

            max(
                15,
                min(
                    45,
                    predicted_days
                )
            )

        )


        print(
            f"ML predicted cycle length: {predicted_days} days"
        )


        # ====================================================
        # CALENDAR CALCULATIONS
        #
        # IMPORTANT:
        # Calendar dates are based on the user's saved
        # cycle length so that the Home Screen remains
        # consistent with the user's actual cycle data.
        #
        # The ML prediction is still returned separately
        # above as "prediction".
        # ====================================================

        calendar_cycle_length = cycle_length


        # ----------------------------------------------------
        # LAST PERIOD DATE
        # ----------------------------------------------------

        last_period = datetime.strptime(

            str(
                last_period_date
            )[:10],

            "%Y-%m-%d"

        )


        # ----------------------------------------------------
        # NEXT PERIOD
        # ----------------------------------------------------

        next_period = (

            last_period

            +

            timedelta(
                days=calendar_cycle_length
            )

        )


        # ----------------------------------------------------
        # OVULATION
        #
        # Approximation:
        # Ovulation is approximately 14 days before the
        # next expected period.
        # ----------------------------------------------------

        ovulation_date = (

            next_period

            -

            timedelta(
                days=14
            )

        )


        # ----------------------------------------------------
        # FERTILE WINDOW
        #
        # Approximately 5 days before ovulation through
        # ovulation day.
        # ----------------------------------------------------

        fertile_start = (

            ovulation_date

            -

            timedelta(
                days=5
            )

        )


        fertile_end = ovulation_date


        # ----------------------------------------------------
        # CONFIDENCE
        # ----------------------------------------------------

        confidence = 87.0


        if hasattr(
            model,
            "predict_proba"
        ):

            try:

                probabilities = model.predict_proba(
                    features
                )

                if probabilities is not None:

                    confidence = round(

                        float(
                            max(
                                probabilities[0]
                            )
                            * 100
                        ),

                        1

                    )

            except Exception:

                confidence = 87.0


        # ----------------------------------------------------
        # CURRENT CYCLE DAY
        # ----------------------------------------------------

        today = datetime.now().date()


        current_day = (

            today

            -

            last_period.date()

        ).days + 1


        if current_day < 1:

            current_day = 1


        # ----------------------------------------------------
        # PHASE
        #
        # Phase is based on the user's saved cycle length,
        # not the ML prediction, so the displayed phase
        # matches the displayed calendar.
        # ----------------------------------------------------

        ovulation_day = (

            calendar_cycle_length

            -

            14

        )


        if current_day <= period_length:

            phase = "Menstrual"

        elif current_day < ovulation_day:

            phase = "Follicular"

        elif current_day <= (
            ovulation_day + 1
        ):

            phase = "Ovulation"

        else:

            phase = "Luteal"


        # ----------------------------------------------------
        # CYCLE PROGRESS
        #
        # Flutter CircularProgressIndicator expects a
        # value between 0.0 and 1.0.
        # ----------------------------------------------------

        cycle_progress = (

            current_day

            /

            max(
                calendar_cycle_length,
                1
            )

        )

        cycle_progress = max(

            0.0,

            min(
                1.0,
                cycle_progress
            )

        )


        # ----------------------------------------------------
        # LOG FINAL CALCULATION
        # ----------------------------------------------------

        print(
            "=============================================="
        )

        print(
            "ASHA CYCLE CALCULATION"
        )

        print(
            f"User cycle length: {calendar_cycle_length}"
        )

        print(
            f"ML predicted cycle length: {predicted_days}"
        )

        print(
            f"Last period: {last_period.strftime('%Y-%m-%d')}"
        )

        print(
            f"Next period: {next_period.strftime('%Y-%m-%d')}"
        )

        print(
            f"Ovulation: {ovulation_date.strftime('%Y-%m-%d')}"
        )

        print(
            f"Fertile window: "
            f"{fertile_start.strftime('%Y-%m-%d')} "
            f"to "
            f"{fertile_end.strftime('%Y-%m-%d')}"
        )

        print(
            f"Current cycle day: {current_day}"
        )

        print(
            f"Phase: {phase}"
        )

        print(
            f"Confidence: {confidence}%"
        )

        print(
            f"Cycle progress: {cycle_progress}"
        )

        print(
            "=============================================="
        )


        # ----------------------------------------------------
        # RESPONSE
        # ----------------------------------------------------

        return jsonify({

            "status":
                "success",

            # ------------------------------------------------
            # ML RESULT
            # ------------------------------------------------

            "prediction":
                predicted_days,

            # Keep this field aligned with the calendar
            # shown in the Home Screen.
            "predicted_cycle_length":
                calendar_cycle_length,

            # Optional explicit ML field for research/demo.
            "ml_predicted_cycle_length":
                predicted_days,

            # ------------------------------------------------
            # CALENDAR RESULT
            # ------------------------------------------------

            "next_period":
                next_period.strftime(
                    "%Y-%m-%d"
                ),

            "next_period_label":
                next_period.strftime(
                    "%d %B %Y"
                ),

            "ovulation_date":
                ovulation_date.strftime(
                    "%Y-%m-%d"
                ),

            "fertile_window": {

                "start":
                    fertile_start.strftime(
                        "%Y-%m-%d"
                    ),

                "end":
                    fertile_end.strftime(
                        "%Y-%m-%d"
                    ),

            },

            "fertile_window_start":
                fertile_start.strftime(
                    "%Y-%m-%d"
                ),

            "fertile_window_end":
                fertile_end.strftime(
                    "%Y-%m-%d"
                ),

            "fertile_window_label":

                f"{fertile_start.strftime('%d %b')} - "
                f"{fertile_end.strftime('%d %b')}",

            # ------------------------------------------------
            # AI CONFIDENCE
            # ------------------------------------------------

            "confidence":
                confidence,

            "ai_confidence":
                confidence,

            # ------------------------------------------------
            # CURRENT CYCLE
            # ------------------------------------------------

            "current_day":
                current_day,

            "cycle_day_at_prediction":
                current_day,

            "phase_label":
                phase,

            "cycle_progress":
                cycle_progress,

            # ------------------------------------------------
            # MODEL INFORMATION
            # ------------------------------------------------

            "factor_weights":
                get_model_feature_importance(),

            "pcos_risk":

                "Higher"

                if pcos == 1

                else

                "Normal",

            # ------------------------------------------------
            # USER PROFILE VALUES
            # ------------------------------------------------

            "avg_cycle_length":
                cycle_length,

            "avg_period_length":
                period_length,

            "cycle_length_history":
                data.get(
                    "period_history",
                    []
                ),

        }), 200


    except Exception as e:

        print(
            "PREDICTION ERROR:",
            str(e)
        )

        return jsonify({

            "status":
                "error",

            "message":
                str(e),

            "error":
                "prediction_failed"

        }), 500


# ============================================================
# GOOGLE PLACES — FIND DOCTORS
# ============================================================

@app.route(
    "/find-doctors",
    methods=["GET", "POST"]
)
def find_doctors():

    try:

        # ----------------------------------------------------
        # CHECK GOOGLE SERVER API KEY
        # ----------------------------------------------------

        if not GOOGLE_MAPS_API_KEY:

            print(
                "ERROR: GOOGLE_MAPS_API_KEY is not configured."
            )

            return jsonify({

                "success":
                    False,

                "error":
                    (
                        "GOOGLE_MAPS_API_KEY is not configured "
                        "on the server."
                    ),

                "facilities":
                    [],

            }), 500


        # ----------------------------------------------------
        # READ LOCATION DATA
        # ----------------------------------------------------

        if request.method == "GET":

            latitude = request.args.get(
                "lat",
                type=float
            )

            longitude = request.args.get(
                "lng",
                type=float
            )

            radius = request.args.get(

                "radius",

                default=5000,

                type=float

            )

        else:

            data = request.get_json(
                silent=True
            ) or {}


            latitude = data.get(
                "latitude"
            )

            if latitude is None:

                latitude = data.get(
                    "lat"
                )


            longitude = data.get(
                "longitude"
            )

            if longitude is None:

                longitude = data.get(
                    "lng"
                )


            radius = data.get(
                "radius",
                5000
            )


            try:

                latitude = float(
                    latitude
                )

                longitude = float(
                    longitude
                )

                radius = float(
                    radius
                )

            except (
                TypeError,
                ValueError
            ):

                return jsonify({

                    "success":
                        False,

                    "error":
                        (
                            "Invalid latitude, longitude, "
                            "or radius."
                        ),

                    "facilities":
                        [],

                }), 400


        # ----------------------------------------------------
        # VALIDATE LOCATION
        # ----------------------------------------------------

        if (
            latitude is None
            or
            longitude is None
        ):

            print(
                "ERROR: Latitude or longitude missing."
            )

            return jsonify({

                "success":
                    False,

                "error":
                    (
                        "Latitude and longitude are required."
                    ),

                "facilities":
                    [],

            }), 400


        try:

            latitude = float(
                latitude
            )

            longitude = float(
                longitude
            )

            radius = float(
                radius
            )

        except (
            TypeError,
            ValueError
        ):

            return jsonify({

                "success":
                    False,

                "error":
                    (
                        "Invalid latitude, longitude, "
                        "or radius."
                    ),

                "facilities":
                    [],

            }), 400


        # ----------------------------------------------------
        # LIMIT SEARCH RADIUS
        # ----------------------------------------------------

        radius = max(

            100,

            min(
                radius,
                50000
            )

        )


        # ----------------------------------------------------
        # LOG REQUEST
        # ----------------------------------------------------

        print(
            "=============================================="
        )

        print(
            "GOOGLE PLACES DOCTOR FINDER"
        )

        print(
            f"Request method: {request.method}"
        )

        print(
            f"Latitude: {latitude}"
        )

        print(
            f"Longitude: {longitude}"
        )

        print(
            f"Radius: {radius}"
        )

        print(
            "Google API key configured:",
            bool(
                GOOGLE_MAPS_API_KEY
            )
        )

        print(
            "=============================================="
        )


        # ----------------------------------------------------
        # GOOGLE PLACES NEARBY SEARCH
        # ----------------------------------------------------

        payload = {

            "includedTypes": [

                "doctor",

                "hospital",

                "general_hospital",

                "medical_center",

                "medical_clinic",

            ],

            "maxResultCount":
                20,

            "rankPreference":
                "DISTANCE",

            "locationRestriction": {

                "circle": {

                    "center": {

                        "latitude":
                            latitude,

                        "longitude":
                            longitude,

                    },

                    "radius":
                        radius,

                }

            },

        }


        # ----------------------------------------------------
        # GOOGLE FIELD MASK
        # ----------------------------------------------------

        field_mask = (

            "places.id,"

            "places.displayName,"

            "places.formattedAddress,"

            "places.location,"

            "places.primaryType,"

            "places.types,"

            "places.rating,"

            "places.currentOpeningHours.openNow"

        )


        # ----------------------------------------------------
        # CALL GOOGLE PLACES API
        # ----------------------------------------------------

        response = requests.post(

            GOOGLE_PLACES_NEARBY_URL,

            json=payload,

            headers=google_headers(
                field_mask
            ),

            timeout=20,

        )


        print(
            "Google Places HTTP status:",
            response.status_code
        )


        # ----------------------------------------------------
        # GOOGLE API ERROR
        # ----------------------------------------------------

        if response.status_code != 200:

            message = google_error_message(
                response
            )

            print(
                "GOOGLE PLACES ERROR:",
                message
            )

            return jsonify({

                "success":
                    False,

                "error":
                    (
                        "Google Places API error: "
                        +
                        message
                    ),

                "facilities":
                    [],

            }), response.status_code


        # ----------------------------------------------------
        # PARSE GOOGLE RESPONSE
        # ----------------------------------------------------

        google_data = response.json()


        places = google_data.get(
            "places",
            []
        )


        print(
            f"Google returned {len(places)} places."
        )


        facilities = []


        # ----------------------------------------------------
        # CONVERT GOOGLE PLACES TO ASHA FORMAT
        # ----------------------------------------------------

        for place in places:

            place_id = place.get(
                "id",
                ""
            )


            display_name = (
                place.get(
                    "displayName"
                )
                or {}
            )


            name = (
                display_name.get(
                    "text"
                )
                or
                "Healthcare Facility"
            )


            location = (
                place.get(
                    "location"
                )
                or {}
            )


            facility_lat = location.get(
                "latitude"
            )

            facility_lng = location.get(
                "longitude"
            )


            if (
                facility_lat is None
                or
                facility_lng is None
            ):

                continue


            address = (
                place.get(
                    "formattedAddress"
                )
                or
                ""
            )


            facility_type = (
                normalize_place_type(
                    place
                )
            )


            rating = place.get(
                "rating"
            )


            current_hours = (
                place.get(
                    "currentOpeningHours"
                )
                or {}
            )


            is_open = (
                current_hours.get(
                    "openNow"
                )
            )


            facilities.append({

                "id":
                    str(
                        place_id
                    ),

                "name":
                    name,

                "latitude":
                    float(
                        facility_lat
                    ),

                "longitude":
                    float(
                        facility_lng
                    ),

                "address":
                    address,

                "type":
                    facility_type,

                "rating":
                    rating,

                "is_open":
                    is_open,

            })


        # ----------------------------------------------------
        # FINAL RESULT
        # ----------------------------------------------------

        print(
            f"Found {len(facilities)} "
            "Google healthcare facilities."
        )


        return jsonify({

            "success":
                True,

            "facilities":
                facilities,

            "count":
                len(facilities),

        }), 200


    # --------------------------------------------------------
    # GOOGLE TIMEOUT
    # --------------------------------------------------------

    except requests.exceptions.Timeout:

        print(
            "Google Places request timed out."
        )

        return jsonify({

            "success":
                False,

            "error":
                (
                    "Google Places request timed out."
                ),

            "facilities":
                [],

        }), 504


    # --------------------------------------------------------
    # GOOGLE CONNECTION ERROR
    # --------------------------------------------------------

    except requests.exceptions.RequestException as e:

        print(
            "Google Places connection error:",
            e
        )

        return jsonify({

            "success":
                False,

            "error":
                (
                    "Could not connect to Google Places."
                ),

            "facilities":
                [],

        }), 502


    # --------------------------------------------------------
    # GENERAL ERROR
    # --------------------------------------------------------

    except Exception as e:

        print(
            "Doctor finder error:",
            e
        )

        return jsonify({

            "success":
                False,

            "error":
                (
                    "Doctor finder server error."
                ),

            "details":
                str(e),

            "facilities":
                [],

        }), 500


# ============================================================
# GOOGLE PLACES — DOCTOR DETAILS
# ============================================================

@app.route(
    "/find-doctors/<path:place_id>",
    methods=["GET"]
)
def get_doctor_details(
    place_id
):

    try:

        if not GOOGLE_MAPS_API_KEY:

            return jsonify({

                "success":
                    False,

                "error":
                    (
                        "GOOGLE_MAPS_API_KEY is not configured."
                    ),

            }), 500


        if not place_id:

            return jsonify({

                "success":
                    False,

                "error":
                    "Place ID is required.",

            }), 400


        url = (

            GOOGLE_PLACES_DETAILS_URL

            + "/"

            + place_id

        )


        field_mask = (

            "id,"

            "displayName,"

            "formattedAddress,"

            "nationalPhoneNumber,"

            "websiteUri,"

            "rating,"

            "currentOpeningHours,"

            "types"

        )


        response = requests.get(

            url,

            headers=google_headers(
                field_mask
            ),

            timeout=20,

        )


        if response.status_code != 200:

            message = google_error_message(
                response
            )

            print(
                "Google Place Details error:",
                message
            )

            return jsonify({

                "success":
                    False,

                "error":
                    (
                        "Google Place Details error: "
                        +
                        message
                    ),

            }), response.status_code


        place = response.json()


        display_name = (

            place.get(
                "displayName"
            )

            or {}

        )


        name = (

            display_name.get(
                "text"
            )

            or
            "Healthcare Facility"

        )


        details = {

            "address":

                place.get(
                    "formattedAddress"
                ),

            "phone":

                place.get(
                    "nationalPhoneNumber"
                ),

            "website":

                place.get(
                    "websiteUri"
                ),

            "opening_hours":

                place.get(
                    "currentOpeningHours"
                ),

            "rating":

                place.get(
                    "rating"
                ),

            "reviews":
                [],

        }


        return jsonify({

            "status":
                "success",

            "success":
                True,

            "name":
                name,

            "details":
                details,

        }), 200


    except requests.exceptions.Timeout:

        return jsonify({

            "success":
                False,

            "error":
                (
                    "Google Place Details request timed out."
                ),

        }), 504


    except requests.exceptions.RequestException as e:

        print(
            "Google Place Details connection error:",
            e
        )

        return jsonify({

            "success":
                False,

            "error":
                (
                    "Could not connect to Google Places."
                ),

        }), 502


    except Exception as e:

        print(
            "Doctor details error:",
            e
        )

        return jsonify({

            "success":
                False,

            "error":
                (
                    "Failed to get facility details."
                ),

            "message":
                str(e),

        }), 500


# ============================================================
# GOOGLE GEOCODING
# ADDRESS → LATITUDE / LONGITUDE
# ============================================================

@app.route(
    "/geocode",
    methods=["POST"]
)
def geocode_address():

    try:

        if not GOOGLE_MAPS_API_KEY:

            return jsonify({

                "success":
                    False,

                "error":
                    (
                        "GOOGLE_MAPS_API_KEY is not configured."
                    ),

            }), 500


        data = request.get_json(
            silent=True
        ) or {}


        address = str(

            data.get(
                "address",
                ""
            )

        ).strip()


        if not address:

            return jsonify({

                "success":
                    False,

                "error":
                    "Address is required.",

            }), 400


        print(
            "Google Geocoding request:",
            address
        )


        params = {

            "address":
                address,

            "regionCode":
                "IN",

        }


        headers = {

            "X-Goog-Api-Key":
                GOOGLE_MAPS_API_KEY,

            "X-Goog-FieldMask":
                (
                    "results.placeId,"
                    "results.location,"
                    "results.formattedAddress"
                ),

        }


        response = requests.get(

            GOOGLE_GEOCODING_URL,

            params=params,

            headers=headers,

            timeout=20,

        )


        if response.status_code != 200:

            message = google_error_message(
                response
            )

            print(
                "Google Geocoding error:",
                message
            )

            return jsonify({

                "success":
                    False,

                "error":
                    (
                        "Google Geocoding API error: "
                        +
                        message
                    ),

            }), response.status_code


        google_data = response.json()


        results = google_data.get(
            "results",
            []
        )


        if not results:

            return jsonify({

                "success":
                    False,

                "error":
                    (
                        "No location found for "
                        "the entered address."
                    ),

            }), 404


        result = results[0]


        location = (

            result.get(
                "location"
            )

            or {}

        )


        latitude = location.get(
            "latitude"
        )

        longitude = location.get(
            "longitude"
        )


        if (
            latitude is None
            or
            longitude is None
        ):

            return jsonify({

                "success":
                    False,

                "error":
                    (
                        "Google did not return "
                        "coordinates."
                    ),

            }), 502


        return jsonify({

            "success":
                True,

            "lat":
                float(
                    latitude
                ),

            "lng":
                float(
                    longitude
                ),

            "display_name":

                result.get(
                    "formattedAddress"
                )
                or
                address,

            "place_id":

                result.get(
                    "placeId"
                ),

        }), 200


    except requests.exceptions.Timeout:

        return jsonify({

            "success":
                False,

            "error":
                (
                    "Google Geocoding request timed out."
                ),

        }), 504


    except requests.exceptions.RequestException as e:

        print(
            "Google Geocoding connection error:",
            e
        )

        return jsonify({

            "success":
                False,

            "error":
                (
                    "Could not connect to Google Geocoding."
                ),

        }), 502


    except Exception as e:

        print(
            "Geocoding error:",
            e
        )

        return jsonify({

            "success":
                False,

            "error":
                (
                    "Geocoding server error."
                ),

            "message":
                str(e),

        }), 500


# ============================================================
# LOG SYMPTOMS
# ============================================================

@app.route(
    "/log/<user_id>",
    methods=["POST"]
)
def log_symptoms(
    user_id
):

    try:

        data = request.get_json(
            silent=True
        ) or {}


        print(
            f"Symptoms logged for user: {user_id}"
        )

        print(
            f"Data: {data}"
        )


        return jsonify({

            "status":
                "success",

            "message":
                "Symptoms logged successfully",

        }), 200


    except Exception as e:

        print(
            "Error logging symptoms:",
            e
        )

        return jsonify({

            "error":
                "Failed to log symptoms",

            "message":
                str(e),

        }), 500


# ============================================================
# ASHA AI CHAT
# ============================================================

@app.route(
    "/chat",
    methods=["POST"]
)
def chat():

    try:

        data = request.get_json(
            silent=True
        ) or {}


        message = data.get(
            "message"
        )


        history = data.get(
            "history",
            []
        )


        if not message:

            return jsonify({

                "error":
                    "No message provided",

                "status":
                    "invalid_request",

            }), 400


        if client is None:

            return jsonify({

                "error":
                    "AI service not available",

                "status":
                    "service_unavailable",

            }), 503


        # ----------------------------------------------------
        # BUILD MESSAGES
        # ----------------------------------------------------

        messages = [

            {

                "role":
                    "system",

                "content":
                    SYSTEM_PROMPT,

            }

        ]


        # ----------------------------------------------------
        # ADD HISTORY
        # ----------------------------------------------------

        if isinstance(
            history,
            list
        ):

            for item in history:

                if not isinstance(
                    item,
                    dict
                ):

                    continue


                role = item.get(

                    "role",

                    "user"

                )


                content = item.get(

                    "content",

                    ""

                )


                if role not in [

                    "user",

                    "assistant"

                ]:

                    role = "user"


                if not content:

                    continue


                messages.append({

                    "role":
                        role,

                    "content":
                        str(
                            content
                        ),

                })


        # ----------------------------------------------------
        # CURRENT MESSAGE
        # ----------------------------------------------------

        messages.append({

            "role":
                "user",

            "content":
                str(
                    message
                ),

        })


        print(
            "=============================================="
        )

        print(
            "ASHA AI CHAT REQUEST"
        )

        print(
            f"Message: {message}"
        )

        print(
            f"History messages: {len(messages) - 2}"
        )

        print(
            "=============================================="
        )


        # ----------------------------------------------------
        # OPENROUTER
        # ----------------------------------------------------

        response = client.chat.completions.create(

            model=AI_PRIMARY_MODEL,

            messages=messages,

            max_tokens=1000,

            extra_body={

                "models":
                    AI_FALLBACK_MODELS,

            },

        )


        # ----------------------------------------------------
        # GET RESPONSE
        # ----------------------------------------------------

        reply = None


        try:

            reply = (

                response

                .choices[0]

                .message

                .content

            )


        except Exception as e:

            print(
                "AI response extraction error:",
                e
            )


        if not reply:

            return jsonify({

                "error":
                    "AI returned an empty response",

                "status":
                    "empty_response",

            }), 502


        actual_model = getattr(

            response,

            "model",

            None

        )


        print(
            "ASHA AI CHAT SUCCESS"
        )

        print(
            f"Model used: {actual_model}"
        )


        return jsonify({

            "status":
                "success",

            "reply":
                reply,

            "model":
                actual_model,

        }), 200


    except Exception as e:

        print(
            "ASHA AI CHAT ERROR:",
            e
        )

        return jsonify({

            "error":
                "Failed to process chat",

            "message":
                str(e),

            "status":
                "server_error",

        }), 500


# ============================================================
# ERROR HANDLERS
# ============================================================

@app.errorhandler(404)
def not_found(
    error
):

    return jsonify({

        "error":
            "Endpoint not found",

        "status":
            "not_found",

    }), 404


@app.errorhandler(405)
def method_not_allowed(
    error
):

    return jsonify({

        "error":
            "Method not allowed",

        "status":
            "method_not_allowed",

    }), 405


@app.errorhandler(500)
def internal_error(
    error
):

    return jsonify({

        "error":
            "Internal server error",

        "status":
            "server_error",

    }), 500


# ============================================================
# RUN SERVER
# ============================================================

if __name__ == "__main__":

    port = int(

        os.environ.get(

            "PORT",

            "10000"

        )

    )


    app.run(

        host="0.0.0.0",

        port=port,

        debug=False

    )