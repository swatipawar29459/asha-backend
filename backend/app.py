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

    except Exception as e:

        print(
            "Could not read model feature importance:",
            e
        )

    return importance


# ============================================================
# FRIENDLY FEATURE NAMES
# ============================================================

FRIENDLY_FEATURE_NAMES = {

    "Cycle Length":
        "Cycle length",

    "Period Length":
        "Period length",

    "Age":
        "Age",

    "BMI":
        "BMI",

    "Stress Level":
        "Stress",

    "Exercise Frequency":
        "Exercise",

    "Sleep Hours":
        "Sleep",

    "Diet":
        "Diet",

    "PCOS":
        "PCOS information"

}


def friendly_feature_name(
    feature_name
):

    return FRIENDLY_FEATURE_NAMES.get(
        feature_name,
        feature_name
    )


# ============================================================
# CLEAN AI RESPONSE
# ============================================================

def clean_ai_response(
    text
):

    if not text:

        return (
            "Sorry, I couldn't generate a response "
            "right now. Please try again."
        )

    text = str(
        text
    ).strip()

    text = re.sub(
        r"<think>.*?</think>",
        "",
        text,
        flags=re.IGNORECASE | re.DOTALL
    )

    text = re.sub(
        r"^\s*(thinking|reasoning|analysis)\s*:\s*.*?\n",
        "",
        text,
        flags=re.IGNORECASE | re.DOTALL
    )

    text = re.sub(
        r"^\s*(final answer|final response)\s*:\s*",
        "",
        text,
        flags=re.IGNORECASE
    )

    text = text.strip()

    if not text:

        return (
            "Sorry, I couldn't generate a response "
            "right now. Please try again."
        )

    return text


# ============================================================
# HEALTH CHECK
# ============================================================

@app.route("/")
def home():

    return jsonify({

        "status":
            "online",

        "message":
            "Asha Flask backend is running"

    })


# ============================================================
# PREDICTION
# ============================================================

@app.route(
    "/predict/<user_id>",
    methods=["POST"]
)
def predict(
    user_id
):

    try:

        # ====================================================
        # CHECK ML MODEL
        # ====================================================

        if model is None:

            return jsonify({

                "error":
                    "ML model is not loaded"

            }), 500


        # ====================================================
        # READ USER DATA
        # ====================================================

        data = request.get_json()

        if not data:

            return jsonify({

                "error":
                    "No user data received"

            }), 400


        print(
            "Prediction request received for user:",
            user_id
        )

        print(
            "Prediction profile:",
            data
        )


        # ====================================================
        # READ USER-PROVIDED VALUES
        #
        # IMPORTANT:
        # No health/profile defaults are used here.
        #
        # The backend must receive the actual values from
        # Flutter.
        # ====================================================

        age = get_int(
            data,
            "age"
        )

        cycle_length = get_int(
            data,
            "cycle_length"
        )

        period_length = get_int(
            data,
            "period_length"
        )

        stress = get_int(
            data,
            "stress_level"
        )

        sleep_hours = get_number(
            data,
            "sleep_hours"
        )

        pcos = get_int(
            data,
            "pcos"
        )

        bmi = get_number(
            data,
            "bmi"
        )

        exercise = encode_exercise(
            data.get(
                "exercise_frequency"
            )
        )

        diet = encode_diet(
            data.get(
                "diet"
            )
        )

        last_period_date = data.get(
            "last_period_date"
        )


        # ====================================================
        # REQUIRED DATA VALIDATION
        # ====================================================

        missing = []


        if age is None:

            missing.append(
                "age"
            )


        if cycle_length is None:

            missing.append(
                "cycle_length"
            )


        if period_length is None:

            missing.append(
                "period_length"
            )


        if stress is None:

            missing.append(
                "stress_level"
            )


        if sleep_hours is None:

            missing.append(
                "sleep_hours"
            )


        if pcos is None:

            missing.append(
                "pcos"
            )


        if bmi is None:

            missing.append(
                "bmi"
            )


        if exercise is None:

            missing.append(
                "exercise_frequency"
            )


        if diet is None:

            missing.append(
                "diet"
            )


        if not last_period_date:

            missing.append(
                "last_period_date"
            )


        elif not is_valid_date_string(
            last_period_date
        ):

            return jsonify({

                "error":
                    "Invalid last period date",

                "details":
                    "Please send last_period_date "
                    "as a valid ISO date."

            }), 400


        # ====================================================
        # STOP IF USER DATA IS MISSING
        # ====================================================

        if missing:

            print(
                "Missing prediction data:",
                missing
            )

            return jsonify({

                "error":
                    "Missing required user data",

                "missing":
                    missing,

                "message":
                    "Please complete your health profile "
                    "before generating a personalized prediction."

            }), 400


        # ====================================================
        # VALIDATE BASIC VALUES
        # ====================================================

        if age <= 0:

            return jsonify({

                "error":
                    "Invalid age"

            }), 400


        if cycle_length <= 0:

            return jsonify({

                "error":
                    "Invalid cycle length"

            }), 400


        if period_length <= 0:

            return jsonify({

                "error":
                    "Invalid period length"

            }), 400


        if bmi <= 0:

            return jsonify({

                "error":
                    "Invalid BMI"

            }), 400


        if sleep_hours < 0:

            return jsonify({

                "error":
                    "Invalid sleep hours"

            }), 400


        if stress < 1 or stress > 5:

            return jsonify({

                "error":
                    "Stress level must be between 1 and 5"

            }), 400


        if pcos not in [0, 1]:

            return jsonify({

                "error":
                    "PCOS value must be 0 or 1"

            }), 400


        # ====================================================
        # BUILD MODEL INPUT
        #
        # These values come from the request sent by Flutter.
        # ====================================================

        raw = {

            "Cycle Length":
                cycle_length,

            "Period Length":
                period_length,

            "Age":
                age,

            "BMI":
                bmi,

            "Stress Level":
                stress,

            "Exercise Frequency":
                exercise,

            "Sleep Hours":
                sleep_hours,

            "Diet":
                diet,

            "PCOS":
                pcos

        }


        print(
            "Actual ML input:",
            raw
        )


        features = pd.DataFrame(
            [raw]
        )[
            FEATURE_ORDER
        ]


        # ====================================================
        # DECISION TREE PREDICTION
        # ====================================================

        predicted_cycle_length = float(
            model.predict(
                features
            )[0]
        )

        predicted_cycle_length = max(
            1,
            round(
                predicted_cycle_length
            )
        )


        print(
            "Predicted cycle length:",
            predicted_cycle_length
        )


        # ====================================================
        # FEATURE IMPORTANCE
        # ====================================================

        raw_importance = (
            get_model_feature_importance()
        )

        factor_weights = {}

        for feature, value in (
            raw_importance.items()
        ):

            factor_weights[
                friendly_feature_name(
                    feature
                )
            ] = value


        # ====================================================
        # LAST PERIOD DATE
        # ====================================================

        try:

            last_date = datetime.fromisoformat(
                str(
                    last_period_date
                ).replace(
                    "Z",
                    "+00:00"
                )
            )

        except Exception:

            return jsonify({

                "error":
                    "Invalid last period date",

                "details":
                    "Could not read the supplied "
                    "last period date."

            }), 400


        if last_date.tzinfo:

            today = datetime.now(
                last_date.tzinfo
            )

        else:

            today = datetime.now()


        today_date = today.date()


        # ====================================================
        # CURRENT CYCLE DAY
        # ====================================================

        current_day = (

            today_date
            -
            last_date.date()

        ).days + 1


        current_day = max(
            1,
            current_day
        )


        # ====================================================
        # EXPECTED NEXT PERIOD
        #
        # The next period is based on:
        #
        # actual user last-period date
        # +
        # ML predicted cycle length
        #
        # Example:
        # Last period = 7 September
        # Predicted cycle = 30 days
        # Expected next period = 7 October
        # ====================================================

        expected_period_date = (

            last_date.date()
            +
            timedelta(
                days=predicted_cycle_length
            )

        )


        # ====================================================
        # CYCLE PROGRESS
        # ====================================================

        cycle_progress = (

            current_day
            /
            predicted_cycle_length

        )

        cycle_progress = max(
            0.0,
            min(
                cycle_progress,
                1.0
            )
        )


        # ====================================================
        # DAYS UNTIL NEXT PERIOD
        # ====================================================

        days_until_period = (

            expected_period_date
            -
            today_date

        ).days


        if days_until_period < 0:

            next_period_label = (
                "Period may be due"
            )

        elif days_until_period == 0:

            next_period_label = (
                "Period due today"
            )

        elif days_until_period == 1:

            next_period_label = (
                "In 1 day"
            )

        else:

            next_period_label = (
                f"In {days_until_period} days"
            )


        # ====================================================
        # CYCLE PHASE
        # ====================================================

        if current_day <= 5:

            phase_label = (
                "Menstrual phase"
            )

        elif current_day <= 13:

            phase_label = (
                "Follicular phase"
            )

        elif current_day <= 16:

            phase_label = (
                "Ovulation approaching"
            )

        else:

            phase_label = (
                "Luteal phase"
            )


        # ====================================================
        # FERTILE WINDOW
        #
        # Approximation based on predicted cycle length.
        # This is NOT a medical diagnosis.
        # ====================================================

        ovulation_day = max(
            1,
            predicted_cycle_length - 14
        )

        fertile_start = max(
            1,
            ovulation_day - 5
        )

        fertile_end = max(
            1,
            ovulation_day
        )

        fertile_window_label = (

            f"Cycle days "
            f"{fertile_start}–"
            f"{fertile_end}"

        )


        # ====================================================
        # PCOS INFORMATION
        # ====================================================

        if pcos == 1:

            pcos_status = (
                "Reported PCOS"
            )

        else:

            pcos_status = (
                "No PCOS reported"
            )


        # ====================================================
        # RESPONSE
        # ====================================================

        return jsonify({

            "user_id":
                user_id,

            "current_day":
                current_day,

            "phase_label":
                phase_label,

            "next_period_label":
                next_period_label,

            "next_period_date":
                expected_period_date.isoformat(),

            "days_until_period":
                days_until_period,

            "fertile_window_label":
                fertile_window_label,

            "cycle_progress":
                cycle_progress,

            "predicted_cycle_length":
                predicted_cycle_length,

            "factor_weights":
                factor_weights,

            "pcos_risk":
                pcos_status,

            "avg_cycle_length":
                cycle_length,

            "avg_period_length":
                period_length,

            "cycle_length_history": [

                cycle_length

            ],

            "input_data": {

                "age":
                    age,

                "cycle_length":
                    cycle_length,

                "period_length":
                    period_length,

                "stress_level":
                    stress,

                "sleep_hours":
                    sleep_hours,

                "bmi":
                    bmi,

                "exercise_frequency":
                    exercise,

                "diet":
                    diet,

                "pcos":
                    pcos,

                "last_period_date":
                    last_period_date

            }

        })


    except Exception as e:

        print(
            "Prediction error:",
            e
        )

        return jsonify({

            "error":
                "Prediction failed",

            "details":
                str(e)

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

        data = request.get_json()

        return jsonify({

            "status":
                "saved",

            "user_id":
                user_id,

            "data":
                data

        })

    except Exception as e:

        print(
            "Log error:",
            e
        )

        return jsonify({

            "error":
                "Could not save log",

            "details":
                str(e)

        }), 500


# ============================================================
# AI CHAT
# ============================================================

@app.route(
    "/chat",
    methods=["POST"]
)
def chat():

    try:

        data = request.get_json()

        if not data:

            return jsonify({

                "error":
                    "Request body is required"

            }), 400


        user_message = str(
            data.get(
                "message",
                ""
            )
        ).strip()


        if not user_message:

            return jsonify({

                "error":
                    "Message is required"

            }), 400


        if client is None:

            print(
                "OpenRouter API key is not configured."
            )

            return jsonify({

                "error":
                    "OpenRouter API key is not configured"

            }), 500


        history = data.get(
            "history",
            []
        )


        messages = [

            {

                "role":
                    "system",

                "content":
                    SYSTEM_PROMPT

            }

        ]


        if isinstance(
            history,
            list
        ):

            for message in history:

                if not isinstance(
                    message,
                    dict
                ):

                    continue


                role = message.get(
                    "role"
                )

                content = message.get(
                    "content"
                )


                if role not in [

                    "user",
                    "assistant"

                ]:

                    continue


                if not content:

                    continue


                messages.append({

                    "role":
                        role,

                    "content":
                        str(content)

                })


        messages.append({

            "role":
                "user",

            "content":
                user_message

        })


        print(
            "Asha user message:",
            user_message
        )


        last_error = None


        for model_name in AI_MODELS:

            try:

                print(
                    "Trying Asha AI model:",
                    model_name
                )


                response = client.chat.completions.create(

                    model=model_name,

                    messages=messages,

                    temperature=0.7,

                    max_tokens=300,

                    extra_body={

                        "reasoning": {

                            "enabled":
                                False

                        }

                    }

                )


                if response is None:

                    raise Exception(
                        "OpenRouter returned no response."
                    )


                if not response.choices:

                    raise Exception(
                        "OpenRouter returned no choices."
                    )


                message = response.choices[0].message


                if message is None:

                    raise Exception(
                        "OpenRouter returned an empty message."
                    )


                reply = message.content


                if not reply:

                    raise Exception(
                        "OpenRouter returned empty content."
                    )


                reply = clean_ai_response(
                    reply
                )


                if not reply:

                    raise Exception(
                        "AI response became empty after cleaning."
                    )


                print(
                    "Asha AI model used:",
                    model_name
                )


                print(
                    "Asha AI reply:",
                    reply
                )


                return jsonify({

                    "reply":
                        reply,

                    "model":
                        model_name

                }), 200


            except Exception as model_error:

                last_error = model_error

                error_text = str(
                    model_error
                )


                print(
                    "Asha model failed:",
                    model_name
                )

                print(
                    "Asha model error:",
                    error_text
                )


                if (

                    "429" in error_text

                    or

                    "rate limit"
                    in
                    error_text.lower()

                    or

                    "rate-limited"
                    in
                    error_text.lower()

                    or

                    "temporarily"
                    in
                    error_text.lower()

                ):

                    print(
                        "Model appears rate-limited."
                    )

                    print(
                        "Trying next Asha AI model..."
                    )


                continue


        print(
            "All Asha AI models failed."
        )


        if last_error:

            print(
                "Last Asha AI error:",
                repr(last_error)
            )


        return jsonify({

            "error":
                "Asha AI is temporarily unavailable.",

            "details":
                "All available AI models were unavailable. "
                "Please try again in a moment."

        }), 503


    except Exception as e:

        print(
            "Asha chat server error:",
            repr(e)
        )


        return jsonify({

            "error":
                "Could not reach Asha AI.",

            "details":
                "The AI service encountered a temporary error."

        }), 503


# ============================================================
# NOTIFICATIONS
# ============================================================

@app.route(
    "/notifications/<user_id>",
    methods=["GET", "POST"]
)
def notifications(
    user_id
):

    return jsonify({

        "notifications": [

            {

                "id":
                    "symptom_reminder",

                "type":
                    "symptom",

                "title":
                    "How are you feeling today?",

                "message":
                    "Take a moment to log your symptoms.",

                "time":
                    "Today",

                "is_read":
                    False

            },

            {

                "id":
                    "wellness",

                "type":
                    "wellness",

                "title":
                    "Take care of yourself today",

                "message":
                    "Stay hydrated, rest well, and listen to your body.",

                "time":
                    "Today",

                "is_read":
                    False

            }

        ]

    })


# ============================================================
# FIND HEALTHCARE
# ============================================================

KURLA_MIN_LAT = 19.045
KURLA_MAX_LAT = 19.085

KURLA_MIN_LNG = 72.865
KURLA_MAX_LNG = 72.910


KURLA_FALLBACK = [

    {

        "name":
            "Aryan Hospital & Medical Centre",

        "type":
            "hospital",

        "address":
            "D-28/29, Nehru Nagar, Station Road, Kurla East, Mumbai, Maharashtra 400024",

        "phone":
            "02225275999",

        "website":
            None,

        "opening_hours":
            "Open 24 hours",

        "lat":
            19.0648,

        "lng":
            72.8848

    },

    {

        "name":
            "Madhavbaug Clinic - Kurla East",

        "type":
            "clinic",

        "address":
            "Bunglow No. 68-C, Kamgar Nagar, Near Tilak Nagar Railway Station, Kurla East, Mumbai 400024",

        "phone":
            "9321123863",

        "website":
            "https://madhavbaug.org/clinic/kurla-east-mumbai",

        "opening_hours":
            "10:00 AM - 7:00 PM; Thursday closed",

        "lat":
            19.0620504,

        "lng":
            72.8876248

    },

    {

        "name":
            "Nehru Nagar Police Dawakhana",

        "type":
            "hospital",

        "address":
            "Ambedkar Garden, Bhiva Bapu Magre Marg, Nehru Nagar, Kurla East, Mumbai",

        "phone":
            None,

        "website":
            None,

        "opening_hours":
            None,

        "lat":
            19.0644615,

        "lng":
            72.8834147

    },

    {

        "name":
            "Maauli Medical",

        "type":
            "clinic",

        "address":
            "8C/Sharad, 16, Kamgaar Nagar, Kurla East, Mumbai",

        "phone":
            None,

        "website":
            None,

        "opening_hours":
            None,

        "lat":
            19.063883,

        "lng":
            72.8888818

    }

]


def is_kurla_area(
    latitude,
    longitude
):

    return (

        KURLA_MIN_LAT
        <=
        latitude
        <=
        KURLA_MAX_LAT

        and

        KURLA_MIN_LNG
        <=
        longitude
        <=
        KURLA_MAX_LNG

    )


def get_kurla_fallback(
    selected_type
):

    fallback = []

    for place in KURLA_FALLBACK:

        if selected_type == "hospital":

            if place["type"] == "hospital":

                fallback.append(
                    dict(place)
                )

        elif selected_type == "clinic":

            if place["type"] == "clinic":

                fallback.append(
                    dict(place)
                )

        else:

            if place["type"] in [

                "hospital",
                "clinic"

            ]:

                doctor_place = dict(
                    place
                )

                doctor_place["type"] = (
                    "doctor"
                )

                fallback.append(
                    doctor_place
                )

    return fallback


@app.route(
    "/doctors",
    methods=["GET"]
)
def doctors():

    lat = request.args.get(
        "lat"
    )

    lng = request.args.get(
        "lng"
    )

    selected_type = (

        request.args.get(
            "type",
            "doctor"
        )
        .lower()
        .strip()

    )


    if selected_type not in [

        "doctor",
        "clinic",
        "hospital"

    ]:

        selected_type = "doctor"


    if not lat or not lng:

        return jsonify({

            "error":
                "Latitude and longitude are required.",

            "results":
                []

        }), 400


    try:

        latitude = float(
            lat
        )

        longitude = float(
            lng
        )

    except (

        TypeError,
        ValueError

    ):

        return jsonify({

            "error":
                "Invalid latitude or longitude.",

            "results":
                []

        }), 400


    # ========================================================
    # KURLA DEMO FALLBACK
    # ========================================================

    if is_kurla_area(
        latitude,
        longitude
    ):

        kurla_results = get_kurla_fallback(
            selected_type
        )

        print(
            "Kurla location detected."
        )

        print(
            f"Returning {len(kurla_results)} "
            "Kurla fallback healthcare results."
        )

        return jsonify({

            "type":
                selected_type,

            "radius_km":
                10,

            "source":
                "ASHA demo healthcare directory",

            "live_results":
                0,

            "results":
                kurla_results

        })


    SEARCH_RADIUS = 10000


    # ========================================================
    # OVERPASS QUERY
    # ========================================================

    if selected_type == "hospital":

        query = f"""
[out:json][timeout:45];
(
  nwr["amenity"="hospital"](around:{SEARCH_RADIUS},{latitude},{longitude});
  nwr["healthcare"="hospital"](around:{SEARCH_RADIUS},{latitude},{longitude});
  nwr["healthcare"="centre"]["healthcare:speciality"](around:{SEARCH_RADIUS},{latitude},{longitude});
);
out center;
"""


    elif selected_type == "clinic":

        query = f"""
[out:json][timeout:45];
(
  nwr["amenity"="clinic"](around:{SEARCH_RADIUS},{latitude},{longitude});
  nwr["healthcare"="clinic"](around:{SEARCH_RADIUS},{latitude},{longitude});
  nwr["healthcare"="centre"](around:{SEARCH_RADIUS},{latitude},{longitude});
  nwr["amenity"="doctors"](around:{SEARCH_RADIUS},{latitude},{longitude});
  nwr["healthcare"="doctor"](around:{SEARCH_RADIUS},{latitude},{longitude});
);
out center;
"""


    else:

        query = f"""
[out:json][timeout:45];
(
  nwr["amenity"="doctors"](around:{SEARCH_RADIUS},{latitude},{longitude});
  nwr["healthcare"="doctor"](around:{SEARCH_RADIUS},{latitude},{longitude});
  nwr["healthcare"="doctors"](around:{SEARCH_RADIUS},{latitude},{longitude});
  nwr["healthcare"="centre"](around:{SEARCH_RADIUS},{latitude},{longitude});
  nwr["amenity"="clinic"](around:{SEARCH_RADIUS},{latitude},{longitude});
  nwr["healthcare"="clinic"](around:{SEARCH_RADIUS},{latitude},{longitude});
  nwr["amenity"="hospital"](around:{SEARCH_RADIUS},{latitude},{longitude});
);
out center;
"""


    overpass_servers = [

        "https://overpass.private.coffee/api/interpreter",

        "https://overpass-api.de/api/interpreter",

        "https://maps.mail.ru/osm/tools/overpass/api/interpreter"

    ]


    headers = {

        "User-Agent":
            "Asha-Womens-Health-App/1.0",

        "Accept":
            "application/json"

    }


    data = None

    last_error = None


    for server in overpass_servers:

        try:

            print(
                "Trying Overpass server:",
                server
            )


            response = requests.post(

                server,

                data={
                    "data":
                        query
                },

                headers=
                    headers,

                timeout=
                    50

            )


            print(
                "Overpass response:",
                response.status_code,
                server
            )


            if response.status_code == 200:

                try:

                    parsed = response.json()

                    if isinstance(
                        parsed,
                        dict
                    ):

                        data = parsed

                        break

                except ValueError as e:

                    last_error = str(
                        e
                    )

            else:

                last_error = (
                    f"HTTP {response.status_code}"
                )


        except requests.exceptions.RequestException as e:

            last_error = str(
                e
            )


    # ========================================================
    # PARSE RESULTS
    # ========================================================

    results = []


    if data is not None:

        elements = data.get(
            "elements",
            []
        )


        for element in elements:

            tags = element.get(
                "tags",
                {}
            )


            if (

                "lat" in element
                and
                "lon" in element

            ):

                place_lat = element.get(
                    "lat"
                )

                place_lng = element.get(
                    "lon"
                )


            elif "center" in element:

                center = element.get(
                    "center",
                    {}
                )

                place_lat = center.get(
                    "lat"
                )

                place_lng = center.get(
                    "lon"
                )


            else:

                continue


            if (

                place_lat is None
                or
                place_lng is None

            ):

                continue


            try:

                place_lat = float(
                    place_lat
                )

                place_lng = float(
                    place_lng
                )

            except (

                TypeError,
                ValueError

            ):

                continue


            name = (

                tags.get(
                    "name"
                )

                or

                tags.get(
                    "name:en"
                )

                or

                tags.get(
                    "official_name"
                )

                or

                tags.get(
                    "operator"
                )

                or

                tags.get(
                    "brand"
                )

                or

                "Healthcare provider"

            )


            address_parts = []


            for key in [

                "addr:housenumber",
                "addr:street",
                "addr:suburb",
                "addr:city",
                "addr:postcode"

            ]:

                value = tags.get(
                    key
                )

                if value:

                    address_parts.append(
                        str(value).strip()
                    )


            address = ", ".join(
                address_parts
            )


            if not address:

                address = (

                    tags.get(
                        "addr:full"
                    )

                    or

                    tags.get(
                        "description"
                    )

                    or

                    ""

                )


            phone = (

                tags.get(
                    "contact:phone"
                )

                or

                tags.get(
                    "phone"
                )

                or

                tags.get(
                    "telephone"
                )

            )


            if phone:

                phone = str(
                    phone
                ).strip()


            website = (

                tags.get(
                    "contact:website"
                )

                or

                tags.get(
                    "website"
                )

                or

                tags.get(
                    "url"
                )

            )


            if website:

                website = str(
                    website
                ).strip()


                if not (

                    website.startswith(
                        "http://"
                    )

                    or

                    website.startswith(
                        "https://"
                    )

                ):

                    website = (
                        "https://"
                        +
                        website
                    )


            opening_hours = tags.get(
                "opening_hours"
            )


            if opening_hours:

                opening_hours = str(
                    opening_hours
                ).strip()


            results.append({

                "name":
                    str(name).strip(),

                "type":
                    selected_type,

                "address":
                    str(address).strip(),

                "phone":
                    phone,

                "website":
                    website,

                "opening_hours":
                    opening_hours,

                "lat":
                    place_lat,

                "lng":
                    place_lng

            })


    # ========================================================
    # REMOVE DUPLICATES
    # ========================================================

    unique_results = []

    seen = set()


    for result in results:

        key = (

            result["name"]
            .lower()
            .strip(),

            round(
                result["lat"],
                5
            ),

            round(
                result["lng"],
                5
            )

        )


        if key in seen:

            continue


        seen.add(
            key
        )

        unique_results.append(
            result
        )


    unique_results = unique_results[:50]


    source = "OpenStreetMap"


    # ========================================================
    # KURLA FALLBACK IF LIVE SEARCH RETURNS NOTHING
    # ========================================================

    if not unique_results:

        if is_kurla_area(

            latitude,
            longitude

        ):

            unique_results = (
                get_kurla_fallback(
                    selected_type
                )
            )

            source = (
                "ASHA demo healthcare directory"
            )

            print(
                "No live OSM results. "
                "Using Kurla fallback."
            )

        else:

            print(
                "No live healthcare results."
            )

            if last_error:

                print(
                    "Last Overpass error:",
                    last_error
                )


    print(
        f"Returning "
        f"{len(unique_results)} "
        f"{selected_type} results."
    )


    return jsonify({

        "type":
            selected_type,

        "radius_km":
            10,

        "source":
            source,

        "live_results":
            len(results),

        "results":
            unique_results

    })


# ============================================================
# GEOCODE ADDRESS
# ============================================================

@app.route(
    "/geocode",
    methods=["GET"]
)
def geocode():

    address = request.args.get(
        "address"
    )


    if not address:

        return jsonify({

            "error":
                "Address is required"

        }), 400


    try:

        response = requests.get(

            "https://nominatim.openstreetmap.org/search",

            params={

                "q":
                    address,

                "format":
                    "json",

                "limit":
                    1

            },

            headers={

                "User-Agent":
                    "Asha-Womens-Health-App/1.0",

                "Accept":
                    "application/json"

            },

            timeout=
                15

        )


        if response.status_code != 200:

            return jsonify({

                "error":
                    "Location service unavailable"

            }), 502


        data = response.json()


        if not data:

            return jsonify({

                "error":
                    "Location not found"

            }), 404


        return jsonify({

            "lat":
                float(
                    data[0]["lat"]
                ),

            "lng":
                float(
                    data[0]["lon"]
                ),

            "display_name":
                data[0]["display_name"]

        })


    except Exception as e:

        print(
            "Geocoding error:",
            e
        )


        return jsonify({

            "error":
                "Could not search for this location."

        }), 502


# ============================================================
# START FLASK
# ============================================================

if __name__ == "__main__":

    app.run(

        host=
            "0.0.0.0",

        port=
            int(
                os.environ.get(
                    "PORT",
                    5000
                )
            ),

        debug=
            False

    )