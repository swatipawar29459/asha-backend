from flask import Flask, jsonify, request
from flask_cors import CORS
import joblib
import pandas as pd
import requests
import os
from datetime import datetime, timedelta
from openai import OpenAI
from dotenv import load_dotenv


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
# OPENROUTER / AI
# ============================================================

OPENROUTER_API_KEY = os.environ.get(
    "OPENROUTER_API_KEY"
)

client = None

if OPENROUTER_API_KEY:
    client = OpenAI(
        base_url="https://openrouter.ai/api/v1",
        api_key=OPENROUTER_API_KEY
    )


# ============================================================
# SYSTEM PROMPT
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
    "You are not a doctor and must never diagnose a "
    "medical condition. "
    "Do not claim certainty about a user's health. "
    "Give general educational and wellness information. "
    "If the user describes severe, persistent, unusual, "
    "or potentially dangerous symptoms, recommend "
    "consulting a qualified healthcare professional. "
    "Be warm, empathetic, clear, and easy to understand. "
    "Keep answers reasonably short unless the user asks "
    "for more detail."
)


# ============================================================
# MODEL
# ============================================================

MODEL_PATH = os.path.join(
    BASE_DIR,
    "final_model.pkl"
)

model = joblib.load(
    MODEL_PATH
)


# ============================================================
# HELPERS
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
        return 1

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
        "high": 2
    }

    return mapping.get(
        value,
        1
    )


def encode_diet(value):

    if value is None:
        return 0

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
        "high protein": 3
    }

    return mapping.get(
        value,
        0
    )


def parse_date(value):

    if not value:
        return None

    try:
        return datetime.fromisoformat(
            str(value).replace(
                "Z",
                "+00:00"
            )
        )
    except Exception:
        return None


def format_date(date):

    return date.strftime(
        "%d/%m/%Y"
    )


# ============================================================
# HOME
# ============================================================

@app.route("/")
def home():

    return jsonify({
        "status": "online",
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
def predict(user_id):

    try:

        data = request.get_json()

        if not data:

            return jsonify({
                "error":
                    "No user data received"
            }), 400

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
            "stress_level",
            3
        )

        sleep_hours = get_number(
            data,
            "sleep_hours",
            7
        )

        pcos = get_int(
            data,
            "pcos",
            0
        )

        bmi = get_number(
            data,
            "bmi",
            22
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

        missing = []

        if age is None:
            missing.append("age")

        if cycle_length is None:
            missing.append(
                "cycle_length"
            )

        if period_length is None:
            missing.append(
                "period_length"
            )

        if missing:

            return jsonify({
                "error":
                    "Missing required user data",
                "missing":
                    missing
            }), 400

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

        feature_order = [
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

        features = pd.DataFrame(
            [raw]
        )[feature_order]

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

        # ----------------------------------------------------
        # LAST PERIOD
        # ----------------------------------------------------

        last_period_date = parse_date(
            data.get(
                "last_period_date"
            )
        )

        current_day = 1

        if last_period_date:

            today = datetime.now(
                last_period_date.tzinfo
                if last_period_date.tzinfo
                else None
            )

            current_day = (
                today.date()
                -
                last_period_date.date()
            ).days + 1

            current_day = max(
                1,
                current_day
            )

        # ----------------------------------------------------
        # PROGRESS
        # ----------------------------------------------------

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

        # ----------------------------------------------------
        # NEXT PERIOD DATE
        # ----------------------------------------------------

        next_period_date = None

        if last_period_date:

            next_period_date = (
                last_period_date
                +
                timedelta(
                    days=
                        predicted_cycle_length
                )
            )

        if next_period_date:

            next_period_label = (
                format_date(
                    next_period_date
                )
            )

        else:

            next_period_label = (
                "Add your last period date"
            )

        # ----------------------------------------------------
        # PHASE
        # ----------------------------------------------------

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

        # ----------------------------------------------------
        # FERTILE WINDOW
        # ----------------------------------------------------

        ovulation_day = (
            predicted_cycle_length
            - 14
        )

        fertile_start_day = max(
            1,
            ovulation_day - 5
        )

        fertile_end_day = max(
            1,
            ovulation_day
        )

        fertile_window_label = (
            f"Cycle days "
            f"{fertile_start_day}–"
            f"{fertile_end_day}"
        )

        if last_period_date:

            ovulation_date = (
                last_period_date
                +
                timedelta(
                    days=
                        ovulation_day - 1
                )
            )

            fertile_start_date = (
                ovulation_date
                -
                timedelta(
                    days=5
                )
            )

            fertile_window_label = (
                f"{format_date(fertile_start_date)} – "
                f"{format_date(ovulation_date)}"
            )

        # ----------------------------------------------------
        # PCOS
        # ----------------------------------------------------

        pcos_risk = (
            True
            if pcos == 1
            else False
        )

        # ----------------------------------------------------
        # RETURN
        # ----------------------------------------------------

        return jsonify({

            "user_id":
                user_id,

            "current_day":
                current_day,

            "phase_label":
                phase_label,

            "confidence":
                87,

            "next_period_label":
                next_period_label,

            "fertile_window_label":
                fertile_window_label,

            "cycle_progress":
                cycle_progress,

            "predicted_cycle_length":
                predicted_cycle_length,

            "factor_weights": {

                "sleep":
                    0.70,

                "stress":
                    0.55,

                "exercise":
                    0.30,

                "history":
                    0.85
            },

            "pcos_risk":
                pcos_risk,

            "avg_cycle_length":
                cycle_length,

            "avg_period_length":
                period_length,

            "cycle_length_history": [
                cycle_length
            ]
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
def log_symptoms(user_id):

    data = request.get_json()

    return jsonify({

        "status":
            "saved",

        "user_id":
            user_id,

        "data":
            data
    })


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

        if "message" not in data:

            return jsonify({
                "error":
                    "Message is required"
            }), 400

        if client is None:

            return jsonify({
                "error":
                    "OpenRouter API key is not configured"
            }), 500

        user_message = data[
            "message"
        ]

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
                str(user_message)

        })

        response = client.chat.completions.create(

            model=
                "openrouter/free",

            messages=
                messages

        )

        reply = (
            response
            .choices[0]
            .message
            .content
        )

        return jsonify({
            "reply":
                reply
        })

    except Exception as e:

        print(
            "OpenRouter error:",
            e
        )

        return jsonify({

            "error":
                "Could not reach Asha AI",

            "details":
                str(e)

        }), 500


# ============================================================
# NOTIFICATIONS
# ============================================================

@app.route(
    "/notifications/<user_id>"
)
def notifications(user_id):

    try:

        # ----------------------------------------------------
        # RECEIVE VALUES FROM FLUTTER
        # ----------------------------------------------------

        last_period_string = request.args.get(
                "last_period_date"
            )

        cycle_length = get_int(
            request.args,
            "cycle_length",
            28
        )

        period_length = get_int(
            request.args,
            "period_length",
            5
        )

        last_period = parse_date(
                last_period_string
            )

        today = datetime.now()

        notifications_list = []

        # ----------------------------------------------------
        # IF USER HAS NO DATE
        # ----------------------------------------------------

        if last_period is None:

            notifications_list.append({

                "id":
                    "cycle",

                "type":
                    "cycle",

                "title":
                    "Update your cycle",

                "message":
                    "Add your last period date so Asha can personalize your cycle predictions.",

                "time":
                    "Today",

                "is_read":
                    False
            })

        else:

            # ------------------------------------------------
            # NORMALIZE DATE
            # ------------------------------------------------

            last_period_day = (
                last_period.replace(
                    tzinfo=None
                )
            )

            today = datetime.now()

            current_day = (
                today.date()
                -
                last_period_day.date()
            ).days + 1

            current_day = max(
                1,
                current_day
            )

            # ------------------------------------------------
            # NEXT PERIOD
            # ------------------------------------------------

            next_period = (
                last_period_day
                +
                timedelta(
                    days=cycle_length
                )
            )

            # ------------------------------------------------
            # OVULATION
            # ------------------------------------------------

            ovulation_date = (
                next_period
                -
                timedelta(
                    days=14
                )
            )

            fertile_start = (
                ovulation_date
                -
                timedelta(
                    days=5
                )
            )

            fertile_end = (
                ovulation_date
            )

            # ------------------------------------------------
            # PERIOD NOTIFICATION
            # ------------------------------------------------

            days_until_period = (
                next_period.date()
                -
                today.date()
            ).days

            if days_until_period == 0:

                period_message = (
                    "Your predicted period may start today."
                )

            elif days_until_period == 1:

                period_message = (
                    "Your predicted period may start tomorrow."
                )

            elif days_until_period > 1:

                period_message = (
                    "Your predicted period is expected on "
                    f"{format_date(next_period)}."
                )

            else:

                period_message = (
                    "Your predicted period date has passed. "
                    "Update your cycle if your period has started."
                )

            notifications_list.append({

                "id":
                    "period",

                "type":
                    "period",

                "title":
                    "Your period prediction",

                "message":
                    period_message,

                "time":
                    "Today",

                "is_read":
                    False
            })

            # ------------------------------------------------
            # FERTILE WINDOW
            # ------------------------------------------------

            if today.date() < fertile_start.date():

                fertile_message = (
                    "Your predicted fertile window is "
                    f"{format_date(fertile_start)} – "
                    f"{format_date(fertile_end)}."
                )

            elif (
                fertile_start.date()
                <= today.date()
                <= fertile_end.date()
            ):

                fertile_message = (
                    "You are currently within your "
                    "predicted fertile window: "
                    f"{format_date(fertile_start)} – "
                    f"{format_date(fertile_end)}."
                )

            else:

                fertile_message = (
                    "Your next predicted fertile window is "
                    f"{format_date(fertile_start)} – "
                    f"{format_date(fertile_end)}."
                )

            notifications_list.append({

                "id":
                    "fertile",

                "type":
                    "fertile",

                "title":
                    "Fertile window",

                "message":
                    fertile_message,

                "time":
                    "Today",

                "is_read":
                    False
            })

            # ------------------------------------------------
            # TODAY'S SYMPTOM REMINDER
            # ------------------------------------------------

            notifications_list.append({

                "id":
                    "symptom",

                "type":
                    "symptom",

                "title":
                    "How are you feeling today?",

                "message":
                    "Take a moment to log your symptoms and keep your cycle history updated.",

                "time":
                    "Today",

                "is_read":
                    False
            })

            # ------------------------------------------------
            # WELLNESS
            # ------------------------------------------------

            notifications_list.append({

                "id":
                    "wellness",

                "type":
                    "wellness",

                "title":
                    "Take care of yourself today",

                "message":
                    "Stay hydrated, get enough rest, and listen to your body.",

                "time":
                    "Today",

                "is_read":
                    False
            })

        return jsonify({

            "user_id":
                user_id,

            "notifications":
                notifications_list

        })

    except Exception as e:

        print(
            "Notification error:",
            e
        )

        return jsonify({

            "error":
                "Could not create notifications",

            "details":
                str(e),

            "notifications":
                []

        }), 500


# ============================================================
# FIND DOCTORS
# OPENSTREETMAP / OVERPASS
# ============================================================

@app.route(
    "/doctors"
)
def doctors():

    lat = request.args.get(
        "lat"
    )

    lng = request.args.get(
        "lng"
    )

    if not lat or not lng:

        return jsonify({

            "error":
                "Latitude and longitude are required.",

            "results":
                []

        }), 400

    query = f"""
[out:json];
(
  node["amenity"="doctors"](around:2000,{lat},{lng});
  node["amenity"="clinic"](around:2000,{lat},{lng});
  node["amenity"="hospital"](around:2000,{lat},{lng});
  node["healthcare"="doctor"](around:2000,{lat},{lng});
  node["healthcare"="clinic"](around:2000,{lat},{lng});
);
out center;
"""

    try:

        response = requests.post(

            "https://overpass-api.de/api/interpreter",

            data={
                "data":
                    query
            },

            headers={
                "User-Agent":
                    "Asha-Womens-Health-App/1.0"
            },

            timeout=30
        )

        if response.status_code != 200:

            return jsonify({

                "error":
                    "OpenStreetMap server error",

                "results":
                    []

            }), 502

        data = response.json()

        elements = data.get(
            "elements",
            []
        )

        results = []

        for element in elements:

            tags = element.get(
                "tags",
                {}
            )

            if (
                "lat" in element
                and "lon" in element
            ):

                doctor_lat = (
                    element["lat"]
                )

                doctor_lng = (
                    element["lon"]
                )

            elif "center" in element:

                doctor_lat = (
                    element[
                        "center"
                    ].get("lat")
                )

                doctor_lng = (
                    element[
                        "center"
                    ].get("lon")
                )

            else:

                continue

            if (
                doctor_lat is None
                or doctor_lng is None
            ):

                continue

            name = (

                tags.get("name")

                or tags.get("operator")

                or tags.get("brand")

                or "Unnamed clinic"
            )

            results.append({

                "name":
                    name,

                "lat":
                    doctor_lat,

                "lng":
                    doctor_lng
            })

        return jsonify({

            "results":
                results

        })

    except Exception as e:

        print(
            "Doctor search error:",
            e
        )

        return jsonify({

            "error":
                "Could not connect to OpenStreetMap.",

            "results":
                []

        }), 502


# ============================================================
# GEOCODE
# NOMINATIM
# ============================================================

@app.route(
    "/geocode"
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
                    "Asha-Womens-Health-App/1.0"

            },

            timeout=15
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
                data[0][
                    "display_name"
                ]
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

        host="0.0.0.0",

        port=int(
            os.environ.get(
                "PORT",
                5000
            )
        ),

        debug=False
    )