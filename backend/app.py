import os
from datetime import datetime, timedelta

import joblib
import requests
from dotenv import load_dotenv
from flask import Flask, jsonify, request
from flask_cors import CORS
from openai import OpenAI


# ============================================================
# LOAD ENVIRONMENT
# ============================================================

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
load_dotenv(os.path.join(BASE_DIR, ".env"))


# ============================================================
# FLASK
# ============================================================

app = Flask(__name__)
CORS(app)


# ============================================================
# OPENROUTER
# ============================================================

OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY")

client = None

if OPENROUTER_API_KEY:
    client = OpenAI(
        base_url="https://openrouter.ai/api/v1",
        api_key=OPENROUTER_API_KEY,
    )


# ============================================================
# LOAD ML MODEL
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

    if value is None or value == "":
        return default

    try:
        return float(value)
    except (TypeError, ValueError):
        return default


def get_int(data, key, default=None):
    value = data.get(key, default)

    if value is None or value == "":
        return default

    try:
        return int(float(value))
    except (TypeError, ValueError):
        return default


def encode_exercise(value):
    if value is None:
        return 1

    if isinstance(value, int):
        return value

    value = str(value).strip().lower()

    if value == "low":
        return 0

    if value == "moderate":
        return 1

    if value == "high":
        return 2

    try:
        return int(float(value))
    except (TypeError, ValueError):
        return 1


def encode_diet(value):
    if value is None:
        return 0

    if isinstance(value, int):
        return value

    value = str(value).strip().lower()

    if value == "low carb":
        return 0

    if value == "balanced":
        return 1

    if value == "vegetarian":
        return 2

    if value == "high protein":
        return 3

    try:
        return int(float(value))
    except (TypeError, ValueError):
        return 0


def parse_date(value):
    if not value:
        return None

    try:
        return datetime.fromisoformat(
            str(value).replace("Z", "+00:00")
        )
    except Exception:
        return None


def format_date(date):
    return date.strftime("%d/%m/%Y")


def calculate_cycle_info(last_period, cycle_length):
    """
    Calculate current cycle day, next period,
    ovulation and fertile window.
    """

    if last_period is None:
        return None

    last_period = last_period.replace(
        tzinfo=None
    )

    today = datetime.now()

    current_cycle_day = (
        today.date() -
        last_period.date()
    ).days + 1

    current_cycle_day = max(
        1,
        current_cycle_day
    )

    next_period = (
        last_period +
        timedelta(days=cycle_length)
    )

    ovulation_date = (
        next_period -
        timedelta(days=14)
    )

    fertile_start = (
        ovulation_date -
        timedelta(days=5)
    )

    fertile_end = ovulation_date

    return {
        "current_cycle_day": current_cycle_day,
        "next_period": next_period,
        "ovulation_date": ovulation_date,
        "fertile_start": fertile_start,
        "fertile_end": fertile_end,
    }


# ============================================================
# HOME / HEALTH CHECK
# ============================================================

@app.route("/", methods=["GET"])
def home():
    return jsonify({
        "status": "Asha backend is online"
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

        data = request.get_json() or {}

        print(
            f"Prediction request received for user: {user_id}"
        )

        print("Prediction data:", data)

        # ----------------------------------------------------
        # REQUIRED VALUES
        # ----------------------------------------------------

        age = get_int(
            data,
            "age"
        )

        cycle_length = get_int(
            data,
            "cycle_length",
            28
        )

        period_length = get_int(
            data,
            "period_length",
            5
        )

        if age is None:
            return jsonify({
                "error": "Age is required."
            }), 400

        if cycle_length is None:
            return jsonify({
                "error": "Cycle length is required."
            }), 400

        if period_length is None:
            return jsonify({
                "error": "Period length is required."
            }), 400

        # ----------------------------------------------------
        # OTHER FEATURES
        # ----------------------------------------------------

        bmi = get_number(
            data,
            "bmi",
            22.0
        )

        stress_level = get_int(
            data,
            "stress_level",
            3
        )

        exercise_frequency = encode_exercise(
            data.get("exercise_frequency")
        )

        sleep_hours = get_number(
            data,
            "sleep_hours",
            7.0
        )

        diet = encode_diet(
            data.get("diet")
        )

        pcos = get_int(
            data,
            "pcos",
            0
        )

        # ----------------------------------------------------
        # MODEL FEATURES
        # ----------------------------------------------------

        features = [[
            cycle_length,
            period_length,
            age,
            bmi,
            stress_level,
            exercise_frequency,
            sleep_hours,
            diet,
            pcos,
        ]]

        # ----------------------------------------------------
        # MODEL PREDICTION
        # ----------------------------------------------------

        if model is not None:

            predicted_cycle_length = model.predict(
                features
            )[0]

            predicted_cycle_length = int(
                round(predicted_cycle_length)
            )

        else:

            predicted_cycle_length = cycle_length

        # Prevent unreasonable predictions
        predicted_cycle_length = max(
            20,
            min(
                predicted_cycle_length,
                45
            )
        )

        # ----------------------------------------------------
        # LAST PERIOD
        # ----------------------------------------------------

        last_period = parse_date(
            data.get("last_period_date")
        )

        cycle_info = calculate_cycle_info(
            last_period,
            predicted_cycle_length
        )

        # ----------------------------------------------------
        # DEFAULT VALUES
        # ----------------------------------------------------

        current_cycle_day = 1
        next_period = None
        ovulation_date = None
        fertile_start = None
        fertile_end = None
        cycle_progress = 0.0
        phase_label = "Unknown"

        if cycle_info:

            current_cycle_day = cycle_info[
                "current_cycle_day"
            ]

            next_period = cycle_info[
                "next_period"
            ]

            ovulation_date = cycle_info[
                "ovulation_date"
            ]

            fertile_start = cycle_info[
                "fertile_start"
            ]

            fertile_end = cycle_info[
                "fertile_end"
            ]

            cycle_progress = (
                current_cycle_day /
                predicted_cycle_length
            )

            cycle_progress = max(
                0.0,
                min(
                    cycle_progress,
                    1.0
                )
            )

            # ------------------------------------------------
            # CYCLE PHASE
            # ------------------------------------------------

            if current_cycle_day <= period_length:

                phase_label = "Menstrual Phase"

            elif current_cycle_day < (
                predicted_cycle_length - 14
            ):

                phase_label = "Follicular Phase"

            elif current_cycle_day <= (
                predicted_cycle_length - 12
            ):

                phase_label = "Ovulation Phase"

            else:

                phase_label = "Luteal Phase"

        # ----------------------------------------------------
        # PCOS RISK
        # ----------------------------------------------------

        if pcos == 1:

            pcos_risk = "Higher"

        elif stress_level >= 4:

            pcos_risk = "Moderate"

        else:

            pcos_risk = "Low"

        # ----------------------------------------------------
        # RESPONSE
        # ----------------------------------------------------

        response = {
            "user_id": user_id,
            "predicted_cycle_length":
                predicted_cycle_length,
            "current_day":
                current_cycle_day,
            "cycle_progress":
                cycle_progress,
            "phase_label":
                phase_label,
            "confidence":
                85,
            "next_period":
                format_date(next_period)
                if next_period
                else None,
            "fertile_window":
                (
                    f"{format_date(fertile_start)} – "
                    f"{format_date(fertile_end)}"
                )
                if fertile_start and fertile_end
                else None,
            "ovulation_date":
                format_date(ovulation_date)
                if ovulation_date
                else None,
            "pcos_risk":
                pcos_risk,
        }

        print(
            "Prediction response:",
            response
        )

        return jsonify(response)

    except Exception as e:

        print(
            "Prediction error:",
            e
        )

        return jsonify({
            "error": "Prediction failed.",
            "details": str(e)
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

        data = request.get_json() or {}

        print(
            f"Log received for user {user_id}:",
            data
        )

        return jsonify({
            "success": True,
            "user_id": user_id,
            "message": "Symptoms logged successfully.",
            "data": data
        })

    except Exception as e:

        return jsonify({
            "error": str(e)
        }), 500


# ============================================================
# CHAT
# ============================================================

@app.route(
    "/chat",
    methods=["POST"]
)
def chat():

    try:

        data = request.get_json() or {}

        message = data.get(
            "message",
            ""
        )

        history = data.get(
            "history",
            []
        )

        if not message:
            return jsonify({
                "error": "Message is required."
            }), 400

        if client is None:
            return jsonify({
                "error":
                    "OpenRouter API key is not configured."
            }), 500

        messages = [
            {
                "role": "system",
                "content": (
                    "You are Asha, a friendly women's "
                    "health assistant. Give helpful, "
                    "clear and supportive wellness "
                    "information. Do not diagnose serious "
                    "medical conditions. Encourage the "
                    "user to consult a qualified doctor "
                    "when appropriate."
                ),
            }
        ]

        # Add previous chat history
        for item in history:

            role = item.get("role")
            content = item.get("content")

            if role in ["user", "assistant"] and content:

                messages.append({
                    "role": role,
                    "content": content
                })

        messages.append({
            "role": "user",
            "content": message
        })

        completion = client.chat.completions.create(
            model="openrouter/free",
            messages=messages,
        )

        reply = completion.choices[0].message.content

        return jsonify({
            "reply": reply
        })

    except Exception as e:

        print(
            "Chat error:",
            e
        )

        return jsonify({
            "error": "Chat failed.",
            "details": str(e)
        }), 500


# ============================================================
# NOTIFICATIONS
# ============================================================

@app.route(
    "/notifications/<user_id>",
    methods=["POST"]
)
def notifications(user_id):

    try:

        # ----------------------------------------------------
        # RECEIVE JSON FROM FLUTTER
        # ----------------------------------------------------

        data = request.get_json(
            silent=True
        ) or {}

        print(
            f"Notification request for user {user_id}:",
            data
        )

        last_period_string = data.get(
            "last_period_date"
        )

        cycle_length = get_int(
            data,
            "cycle_length",
            28
        )

        period_length = get_int(
            data,
            "period_length",
            5
        )

        last_period = parse_date(
            last_period_string
        )

        notifications_list = []

        # ----------------------------------------------------
        # NO LAST PERIOD
        # ----------------------------------------------------

        if last_period is None:

            notifications_list.append({
                "id": "cycle",
                "type": "cycle",
                "title": "Update your cycle",
                "message":
                    "Add your last period date so Asha can personalize your cycle predictions.",
                "time": "Today",
                "is_read": False
            })

        else:

            last_period = last_period.replace(
                tzinfo=None
            )

            today = datetime.now()

            # ------------------------------------------------
            # CURRENT CYCLE DAY
            # ------------------------------------------------

            current_cycle_day = (
                today.date()
                -
                last_period.date()
            ).days + 1

            current_cycle_day = max(
                1,
                current_cycle_day
            )

            # ------------------------------------------------
            # NEXT PERIOD
            # ------------------------------------------------

            next_period = (
                last_period
                +
                timedelta(
                    days=cycle_length
                )
            )

            # ------------------------------------------------
            # FERTILE WINDOW
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

            fertile_end = ovulation_date

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
                "id": "period",
                "type": "period",
                "title": "Your period prediction",
                "message": period_message,
                "time": "Today",
                "is_read": False
            })

            # ------------------------------------------------
            # FERTILE WINDOW NOTIFICATION
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

                # Current fertile window has passed.
                # Calculate the next one.

                next_ovulation = (
                    ovulation_date
                    +
                    timedelta(
                        days=cycle_length
                    )
                )

                next_fertile_start = (
                    next_ovulation
                    -
                    timedelta(
                        days=5
                    )
                )

                fertile_message = (
                    "Your next predicted fertile window is "
                    f"{format_date(next_fertile_start)} – "
                    f"{format_date(next_ovulation)}."
                )

            notifications_list.append({
                "id": "fertile",
                "type": "fertile",
                "title": "Fertile window",
                "message": fertile_message,
                "time": "Today",
                "is_read": False
            })

            # ------------------------------------------------
            # SYMPTOM NOTIFICATION
            # ------------------------------------------------

            notifications_list.append({
                "id": "symptom",
                "type": "symptom",
                "title": "How are you feeling today?",
                "message":
                    "Take a moment to log your symptoms and keep your cycle history updated.",
                "time": "Today",
                "is_read": False
            })

            # ------------------------------------------------
            # WELLNESS NOTIFICATION
            # ------------------------------------------------

            notifications_list.append({
                "id": "wellness",
                "type": "wellness",
                "title": "Take care of yourself today",
                "message":
                    "Stay hydrated, get enough rest, and listen to your body.",
                "time": "Today",
                "is_read": False
            })

        return jsonify({
            "user_id": user_id,
            "notifications": notifications_list
        })

    except Exception as e:

        print(
            "Notification error:",
            e
        )

        return jsonify({
            "error":
                "Could not create notifications.",
            "details":
                str(e),
            "notifications":
                []
        }), 500


# ============================================================
# DOCTORS
# ============================================================

@app.route(
    "/doctors",
    methods=["GET"]
)
def doctors():

    try:

        lat = request.args.get(
            "lat",
            type=float
        )

        lng = request.args.get(
            "lng",
            type=float
        )

        if lat is None or lng is None:

            return jsonify({
                "error":
                    "Latitude and longitude are required."
            }), 400

        print(
            f"Doctor search: {lat}, {lng}"
        )

        # ----------------------------------------------------
        # SEARCH WITHIN 5 KM
        # ----------------------------------------------------

        query = f"""
[out:json][timeout:25];

(
  node["amenity"="doctors"](around:10000,{lat},{lng});
  node["amenity"="clinic"](around:10000,{lat},{lng});
  node["amenity"="hospital"](around:10000,{lat},{lng});
  node["healthcare"="doctor"](around:10000,{lat},{lng});
  node["healthcare"="clinic"](around:10000,{lat},{lng});
  way["amenity"="doctors"](around:10000,{lat},{lng});
  way["amenity"="clinic"](around:10000,{lat},{lng});
  way["amenity"="hospital"](around:10000,{lat},{lng});
  way["healthcare"="doctor"](around:10000,{lat},{lng});
  way["healthcare"="clinic"](around:10000,{lat},{lng});
);

out center;
"""

        response = requests.post(
            "https://overpass-api.de/api/interpreter",
            data=query,
            timeout=30
        )

        response.raise_for_status()

        data = response.json()

        results = []

        for element in data.get(
            "elements",
            []
        ):

            tags = element.get(
                "tags",
                {}
            )

            name = (
                tags.get("name")
                or tags.get("operator")
                or tags.get("brand")
                or "Unnamed clinic"
            )

            element_lat = element.get(
                "lat"
            )

            element_lng = element.get(
                "lon"
            )

            # Some OSM elements are areas and use center
            if (
                element_lat is None
                or element_lng is None
            ):

                center = element.get(
                    "center",
                    {}
                )

                element_lat = center.get(
                    "lat"
                )

                element_lng = center.get(
                    "lon"
                )

            if (
                element_lat is None
                or element_lng is None
            ):
                continue

            results.append({
                "name": name,
                "lat": float(element_lat),
                "lng": float(element_lng),
            })

        # ----------------------------------------------------
        # REMOVE DUPLICATES
        # ----------------------------------------------------

        unique_results = []

        seen = set()

        for doctor in results:

            key = (
                doctor["name"],
                round(doctor["lat"], 5),
                round(doctor["lng"], 5)
            )

            if key not in seen:

                seen.add(key)
                unique_results.append(
                    doctor
                )

        # ----------------------------------------------------
        # LIMIT RESULTS
        # ----------------------------------------------------

        unique_results = unique_results[:50]

        print(
            f"Found {len(unique_results)} doctors/clinics."
        )

        return jsonify({
            "results": unique_results
        })

    except requests.RequestException as e:

        print(
            "Overpass error:",
            e
        )

        return jsonify({
            "error":
                "Could not contact the doctor search service.",
            "results": []
        }), 502

    except Exception as e:

        print(
            "Doctor search error:",
            e
        )

        return jsonify({
            "error":
                "Could not find nearby doctors.",
            "details":
                str(e),
            "results": []
        }), 500


# ============================================================
# GEOCODE ADDRESS
# ============================================================

# ============================================================
# GEOCODE ADDRESS
# ============================================================

@app.route(
    "/geocode",
    methods=["GET"]
)
def geocode():

    try:

        address = request.args.get(
            "address",
            ""
        ).strip()

        if not address:
            return jsonify({
                "error": "Address is required."
            }), 400

        # Make Indian location searches more specific
        search_address = address

        if "india" not in address.lower():
            search_address = f"{address}, Mumbai, Maharashtra, India"

        print(
            f"Geocoding address: {search_address}"
        )

        response = requests.get(
            "https://nominatim.openstreetmap.org/search",
            params={
                "q": search_address,
                "format": "json",
                "limit": 1,
                "countrycodes": "in",
            },
            headers={
                "User-Agent":
                    "Asha-Womens-Health-App/1.0"
            },
            timeout=15
        )

        response.raise_for_status()

        results = response.json()

        print(
            "Geocoding results:",
            results
        )

        if not results:
            return jsonify({
                "error": "Address not found."
            }), 404

        result = results[0]

        return jsonify({
            "lat": float(result["lat"]),
            "lng": float(result["lon"]),
            "display_name":
                result.get(
                    "display_name",
                    search_address
                )
        })

    except requests.RequestException as e:

        print(
            "Geocoding error:",
            e
        )

        return jsonify({
            "error":
                "Could not contact the address search service."
        }), 502

    except Exception as e:

        print(
            "Geocoding error:",
            e
        )

        return jsonify({
            "error":
                "Could not find the address.",
            "details":
                str(e)
        }), 500

# ============================================================
# RUN
# ============================================================

if __name__ == "__main__":

    port = int(
        os.getenv(
            "PORT",
            5000
        )
    )

    app.run(
        host="0.0.0.0",
        port=port,
        debug=False
    )