
from flask import Flask, jsonify, request
from flask_cors import CORS
import joblib
import pandas as pd
import requests
import os
from openai import OpenAI
from dotenv import load_dotenv
from datetime import datetime


# ============================================================
# LOAD ENVIRONMENT VARIABLES
# ============================================================

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

load_dotenv(
    os.path.join(BASE_DIR, ".env")
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
        api_key=OPENROUTER_API_KEY
    )


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

    "You are not a doctor and must never diagnose a medical "
    "condition. "

    "Do not claim certainty about a user's health. "

    "Give general educational and wellness information. "

    "If the user describes severe, persistent, unusual, or "
    "potentially dangerous symptoms, recommend consulting "
    "a qualified healthcare professional. "

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
    model = joblib.load(MODEL_PATH)
    print("ML model loaded successfully.")
except Exception as e:
    model = None
    print("Could not load ML model:", e)


# ============================================================
# HELPER FUNCTIONS
# ============================================================

def get_number(data, key, default=None):
    value = data.get(key, default)

    if value is None:
        return default

    try:
        return float(value)
    except (TypeError, ValueError):
        return default


def get_int(data, key, default=None):
    """
    Safely convert a value received from Flutter to integer.
    """

    value = data.get(key, default)

    if value is None:
        return default

    try:
        return int(float(value))
    except (TypeError, ValueError):
        return default


def encode_exercise(value):
    """
    Convert Flutter exercise value to numeric value.

    Low -> 0
    Moderate -> 1
    High -> 2
    """

    if value is None:
        return 1

    if isinstance(value, (int, float)):
        return int(value)

    value = str(value).strip().lower()

    mapping = {
        "low": 0,
        "moderate": 1,
        "high": 2
    }

    return mapping.get(value, 1)


def encode_diet(value):
    """
    Convert Flutter diet value to numeric value.

    IMPORTANT:
    This mapping must match the mapping used
    when the ML model was trained.
    """

    if value is None:
        return 0

    if isinstance(value, (int, float)):
        return int(value)

    value = str(value).strip().lower()

    mapping = {
        "low carb": 0,
        "balanced": 1,
        "vegetarian": 2,
        "high protein": 3
    }

    return mapping.get(value, 0)


# ============================================================
# HEALTH CHECK
# ============================================================

@app.route("/")
def home():

    return jsonify({
        "status": "online",
        "message": "Asha Flask backend is running"
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

        # ----------------------------------------------------
        # CHECK MODEL
        # ----------------------------------------------------

        if model is None:

            return jsonify({
                "error": "ML model is not loaded"
            }), 500


        # ----------------------------------------------------
        # GET JSON DATA
        # ----------------------------------------------------

        data = request.get_json()

        if not data:

            return jsonify({
                "error": "No user data received"
            }), 400


        # ----------------------------------------------------
        # GET USER DATA FROM FLUTTER
        # ----------------------------------------------------

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
            data.get("exercise_frequency")
        )

        diet = encode_diet(
            data.get("diet")
        )


        # ----------------------------------------------------
        # VALIDATE REQUIRED VALUES
        # ----------------------------------------------------

        missing = []

        if age is None:
            missing.append("age")

        if cycle_length is None:
            missing.append("cycle_length")

        if period_length is None:
            missing.append("period_length")

        if missing:

            return jsonify({
                "error": "Missing required user data",
                "missing": missing
            }), 400


        # ----------------------------------------------------
        # CREATE ML INPUT
        # ----------------------------------------------------

        raw = {

            "Cycle Length": cycle_length,

            "Period Length": period_length,

            "Age": age,

            "BMI": bmi,

            "Stress Level": stress,

            "Exercise Frequency": exercise,

            "Sleep Hours": sleep_hours,

            "Diet": diet,

            "PCOS": pcos
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


        # ----------------------------------------------------
        # ML PREDICTION
        # ----------------------------------------------------

        predicted_cycle_length = float(
            model.predict(features)[0]
        )

        predicted_cycle_length = max(
            1,
            round(predicted_cycle_length)
        )


        # ----------------------------------------------------
        # LAST PERIOD DATE
        # ----------------------------------------------------

        last_period_date = data.get(
            "last_period_date"
        )

        current_day = 1

        if last_period_date:

            try:

                last_date = datetime.fromisoformat(
                    last_period_date.replace(
                        "Z",
                        "+00:00"
                    )
                )

                if last_date.tzinfo:

                    today = datetime.now(
                        last_date.tzinfo
                    )

                else:

                    today = datetime.now()


                current_day = (
                    today.date()
                    - last_date.date()
                ).days + 1

                current_day = max(
                    1,
                    current_day
                )

            except Exception as e:

                print(
                    "Last period date error:",
                    e
                )

                current_day = 1


        # ----------------------------------------------------
        # CYCLE PROGRESS
        # ----------------------------------------------------

        cycle_progress = (
            current_day /
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
        # DAYS UNTIL NEXT PERIOD
        # ----------------------------------------------------

        days_until_period = (
            predicted_cycle_length
            - current_day
        )

        if days_until_period <= 0:

            next_period_label = "Period may be due"

        else:

            next_period_label = (
                f"In {days_until_period} days"
            )


        # ----------------------------------------------------
        # CYCLE PHASE
        # ----------------------------------------------------

        if current_day <= 5:

            phase_label = "Menstrual phase"

        elif current_day <= 13:

            phase_label = "Follicular phase"

        elif current_day <= 16:

            phase_label = "Ovulation approaching"

        else:

            phase_label = "Luteal phase"


        # ----------------------------------------------------
        # FERTILE WINDOW
        # ----------------------------------------------------

        ovulation_day = (
            predicted_cycle_length - 14
        )

        fertile_start = (
            ovulation_day - 5
        )

        fertile_end = ovulation_day

        fertile_window_label = (
            f"Cycle days "
            f"{max(1, fertile_start)}–"
            f"{max(1, fertile_end)}"
        )


        # ----------------------------------------------------
        # PCOS WELLNESS SIGNAL
        # ----------------------------------------------------

        pcos_risk = (
            True
            if pcos == 1
            else False
        )


        # ----------------------------------------------------
        # RETURN RESULT
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
                "error": "Request body is required"
            }), 400

        user_message = str(
            data.get("message", "")
        ).strip()

        if not user_message:
            return jsonify({
                "error": "Message is required"
            }), 400

        if client is None:
            return jsonify({
                "error": "OpenRouter API key is not configured"
            }), 500

        history = data.get("history", [])

        messages = [
            {
                "role": "system",
                "content": SYSTEM_PROMPT
            }
        ]

        # Add previous conversation messages
        if isinstance(history, list):

            for message in history:

                if not isinstance(message, dict):
                    continue

                role = message.get("role")
                content = message.get("content")

                if role not in ["user", "assistant"]:
                    continue

                if not content:
                    continue

                messages.append({
                    "role": role,
                    "content": str(content)
                })

        # Add current user message
        messages.append({
            "role": "user",
            "content": user_message
        })

        print("Asha user message:", user_message)

        response = client.chat.completions.create(
            model="google/gemma-4-26b-a4b-it:free",
            messages=messages,
            temperature=0.7,
            max_tokens=300
        )

        reply = (
            response
            .choices[0]
            .message
            .content
        )

        if not reply:
            reply = (
                "Sorry, I couldn't generate a response "
                "right now. Please try again."
            )

        print("Asha AI reply:", reply)

        return jsonify({
            "reply": str(reply).strip()
        })

    except Exception as e:

        print(
            "OpenRouter error:",
            repr(e)
        )

        return jsonify({
            "error": "Could not reach Asha AI",
            "details": str(e)
        }), 500

# ============================================================
# NOTIFICATIONS
# ============================================================

@app.route(
    "/notifications/<user_id>"
)
def notifications(user_id):

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
# FIND DOCTORS / CLINICS / HOSPITALS
# ============================================================

@app.route("/doctors")
def doctors():

    lat = request.args.get("lat")
    lng = request.args.get("lng")

    if not lat or not lng:
        return jsonify({
            "error": "Latitude and longitude are required.",
            "results": []
        }), 400

    # Search approximately 3 km around the selected location.
    query = f"""
[out:json][timeout:20];

(
  nwr["amenity"="doctors"](around:3000,{lat},{lng});
  nwr["amenity"="clinic"](around:3000,{lat},{lng});
  nwr["amenity"="hospital"](around:3000,{lat},{lng});

  nwr["healthcare"="doctor"](around:3000,{lat},{lng});
  nwr["healthcare"="clinic"](around:3000,{lat},{lng});
  nwr["healthcare"="hospital"](around:3000,{lat},{lng});
);

out center;
"""

    # Multiple public Overpass servers.
    overpass_servers = [
        "https://overpass-api.de/api/interpreter",
        "https://overpass.private.coffee/api/interpreter",
        "https://maps.mail.ru/osm/tools/overpass/api/interpreter",
    ]

    last_error = None

    for server in overpass_servers:

        try:

            print(
                "Trying Overpass server:",
                server
            )

            response = requests.post(
                server,
                data={"data": query},
                headers={
                    "User-Agent":
                        "Asha-Womens-Health-App/1.0"
                },
                timeout=25
            )

            print(
                "Overpass response:",
                response.status_code
            )

            if response.status_code != 200:
                last_error = (
                    f"Server returned "
                    f"{response.status_code}"
                )
                continue

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

                # ------------------------------------------------
                # GET LOCATION
                # ------------------------------------------------

                if (
                    "lat" in element
                    and "lon" in element
                ):
                    place_lat = element["lat"]
                    place_lng = element["lon"]

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
                    or place_lng is None
                ):
                    continue

                # ------------------------------------------------
                # GET NAME
                # ------------------------------------------------

                name = (
                    tags.get("name")
                    or tags.get("official_name")
                    or tags.get("operator")
                    or tags.get("brand")
                    or "Unnamed medical facility"
                )

                # ------------------------------------------------
                # DETERMINE TYPE
                # ------------------------------------------------

                healthcare_type = (
                    tags.get("healthcare")
                    or ""
                ).lower()

                amenity_type = (
                    tags.get("amenity")
                    or ""
                ).lower()

                if (
                    healthcare_type == "hospital"
                    or amenity_type == "hospital"
                ):
                    place_type = "Hospital"

                elif (
                    healthcare_type == "clinic"
                    or amenity_type == "clinic"
                ):
                    place_type = "Clinic"

                elif (
                    healthcare_type == "doctor"
                    or amenity_type == "doctors"
                ):
                    place_type = "Doctor"

                else:
                    place_type = "Medical facility"

                results.append({
                    "name": name,
                    "lat": place_lat,
                    "lng": place_lng,
                    "type": place_type
                })

            # ------------------------------------------------
            # REMOVE DUPLICATES
            # ------------------------------------------------

            unique_results = []
            seen = set()

            for place in results:

                key = (
                    place["name"].lower(),
                    round(place["lat"], 5),
                    round(place["lng"], 5)
                )

                if key in seen:
                    continue

                seen.add(key)
                unique_results.append(place)

            # Limit results so the app stays clean.
            unique_results = unique_results[:50]

            print(
                "Medical facilities found:",
                len(unique_results)
            )

            return jsonify({
                "results": unique_results
            })

        except Exception as e:

            print(
                "Overpass server failed:",
                server,
                repr(e)
            )

            last_error = str(e)

    # All servers failed.
    print(
        "All Overpass servers failed:",
        last_error
    )

    return jsonify({
        "error":
            "Could not connect to medical search service.",
        "results": []
    }), 502


# ============================================================
# GEOCODE ADDRESS
# OPENSTREETMAP / NOMINATIM
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

        host="0.0.0.0",

        port=int(
            os.environ.get(
                "PORT",
                5000
            )
        ),

        debug=False

    )

