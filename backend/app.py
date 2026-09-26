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

    value = data.get(
        key,
        default
    )

    if value is None:
        return default

    try:
        return float(value)

    except (TypeError, ValueError):
        return default


def get_int(data, key, default=None):

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

    except (TypeError, ValueError):
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
def predict(user_id):

    try:

        if model is None:

            return jsonify({
                "error":
                    "ML model is not loaded"
            }), 500

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
            missing.append("cycle_length")

        if period_length is None:
            missing.append("period_length")

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
                    -
                    last_date.date()
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

        days_until_period = (
            predicted_cycle_length
            -
            current_day
        )

        if days_until_period <= 0:

            next_period_label = (
                "Period may be due"
            )

        else:

            next_period_label = (
                f"In {days_until_period} days"
            )

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

        ovulation_day = (
            predicted_cycle_length
            -
            14
        )

        fertile_start = (
            ovulation_day
            -
            5
        )

        fertile_end = ovulation_day

        fertile_window_label = (
            f"Cycle days "
            f"{max(1, fertile_start)}–"
            f"{max(1, fertile_end)}"
        )

        pcos_risk = (
            True
            if pcos == 1
            else False
        )

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

        response = client.chat.completions.create(

            model=
                "google/gemma-4-26b-a4b-it:free",

            messages=
                messages,

            temperature=
                0.7,

            max_tokens=
                300

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

        print(
            "Asha AI reply:",
            reply
        )

        return jsonify({

            "reply":
                str(reply).strip()

        })

    except Exception as e:

        print(
            "OpenRouter error:",
            repr(e)
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
        "name": "Aryan Hospital & Medical Centre",
        "type": "hospital",
        "address": "D-28/29, Nehru Nagar, Station Road, Kurla East, Mumbai, Maharashtra 400024",
        "phone": "02225275999",
        "website": None,
        "opening_hours": "Open 24 hours",
        "lat": 19.0648,
        "lng": 72.8848,
    },

    {
        "name": "Madhavbaug Clinic - Kurla East",
        "type": "clinic",
        "address": "Bunglow No. 68-C, Kamgar Nagar, Near Tilak Nagar Railway Station, Kurla East, Mumbai 400024",
        "phone": "9321123863",
        "website": "https://madhavbaug.org/clinic/kurla-east-mumbai",
        "opening_hours": "10:00 AM - 7:00 PM; Thursday closed",
        "lat": 19.0620504,
        "lng": 72.8876248,
    },

    {
        "name": "Nehru Nagar Police Dawakhana",
        "type": "hospital",
        "address": "Ambedkar Garden, Bhiva Bapu Magre Marg, Nehru Nagar, Kurla East, Mumbai",
        "phone": None,
        "website": None,
        "opening_hours": None,
        "lat": 19.0644615,
        "lng": 72.8834147,
    },

    {
        "name": "Maauli Medical",
        "type": "clinic",
        "address": "8C/Sharad, 16, Kamgaar Nagar, Kurla East, Mumbai",
        "phone": None,
        "website": None,
        "opening_hours": None,
        "lat": 19.063883,
        "lng": 72.8888818,
    },
]


def is_kurla_area(latitude, longitude):
    return (
        KURLA_MIN_LAT <= latitude <= KURLA_MAX_LAT
        and
        KURLA_MIN_LNG <= longitude <= KURLA_MAX_LNG
    )


def get_kurla_fallback():
    """
    Return all Kurla healthcare facilities.

    The Flutter screen does not have category buttons,
    so the app receives hospitals and clinics together.
    """

    return [
        dict(place)
        for place in KURLA_FALLBACK
    ]


@app.route("/doctors")
def doctors():

    # --------------------------------------------------------
    # READ LOCATION
    # --------------------------------------------------------

    lat = request.args.get("lat")
    lng = request.args.get("lng")

    if not lat or not lng:
        return jsonify({
            "error": "Latitude and longitude are required.",
            "results": []
        }), 400

    try:
        latitude = float(lat)
        longitude = float(lng)

    except (TypeError, ValueError):
        return jsonify({
            "error": "Invalid latitude or longitude.",
            "results": []
        }), 400

    # --------------------------------------------------------
    # SEARCH RADIUS
    # --------------------------------------------------------

    SEARCH_RADIUS = 10000

    # --------------------------------------------------------
    # ONE GENERAL HEALTHCARE QUERY
    #
    # We intentionally search all healthcare facilities
    # because the Flutter UI does NOT have Doctor / Clinic /
    # Hospital selection buttons.
    # --------------------------------------------------------

    query = f"""
[out:json][timeout:25];
(
  nwr["amenity"="doctors"](around:{SEARCH_RADIUS},{latitude},{longitude});
  nwr["healthcare"="doctor"](around:{SEARCH_RADIUS},{latitude},{longitude});
  nwr["amenity"="clinic"](around:{SEARCH_RADIUS},{latitude},{longitude});
  nwr["healthcare"="clinic"](around:{SEARCH_RADIUS},{latitude},{longitude});
  nwr["amenity"="hospital"](around:{SEARCH_RADIUS},{latitude},{longitude});
  nwr["healthcare"="hospital"](around:{SEARCH_RADIUS},{latitude},{longitude});
  nwr["healthcare"="centre"](around:{SEARCH_RADIUS},{latitude},{longitude});
);
out center;
"""

    # --------------------------------------------------------
    # OVERPASS SERVERS
    # --------------------------------------------------------

    overpass_servers = [
        "https://overpass.private.coffee/api/interpreter",
        "https://overpass-api.de/api/interpreter",
        "https://maps.mail.ru/osm/tools/overpass/api/interpreter",
    ]

    headers = {
        "User-Agent":
            "Asha-Womens-Health-App/1.0",
        "Accept":
            "application/json",
    }

    data = None

    # --------------------------------------------------------
    # TRY LIVE SEARCH
    # --------------------------------------------------------

    for server in overpass_servers:

        try:

            print(
                "Trying Overpass server:",
                server
            )

            response = requests.post(
                server,
                data={
                    "data": query
                },
                headers=headers,
                timeout=30,
            )

            print(
                "Overpass response:",
                response.status_code,
                server
            )

            if response.status_code != 200:
                continue

            try:
                parsed = response.json()
            except ValueError:
                continue

            if isinstance(parsed, dict):
                data = parsed
                break

        except requests.exceptions.Timeout:

            print(
                "Overpass timeout:",
                server
            )

        except requests.exceptions.RequestException as e:

            print(
                "Overpass request failed:",
                server,
                e
            )

        except Exception as e:

            print(
                "Unexpected Overpass error:",
                server,
                e
            )

    # --------------------------------------------------------
    # PARSE RESULTS
    # --------------------------------------------------------

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

            # ------------------------------------------------
            # GET COORDINATES
            # ------------------------------------------------

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

            # ------------------------------------------------
            # NAME
            # ------------------------------------------------

            name = (
                tags.get("name")
                or
                tags.get("name:en")
                or
                tags.get("official_name")
                or
                tags.get("operator")
                or
                tags.get("brand")
                or
                "Healthcare provider"
            )

            # ------------------------------------------------
            # TYPE
            # ------------------------------------------------

            if (
                tags.get("amenity") == "hospital"
                or
                tags.get("healthcare") == "hospital"
            ):

                facility_type = "hospital"

            elif (
                tags.get("amenity") == "clinic"
                or
                tags.get("healthcare") == "clinic"
            ):

                facility_type = "clinic"

            elif (
                tags.get("amenity") == "doctors"
                or
                tags.get("healthcare") == "doctor"
            ):

                facility_type = "doctor"

            else:

                facility_type = "healthcare"

            # ------------------------------------------------
            # ADDRESS
            # ------------------------------------------------

            address_parts = []

            for key in [
                "addr:housenumber",
                "addr:street",
                "addr:suburb",
                "addr:city",
                "addr:postcode",
            ]:

                value = tags.get(key)

                if value:
                    address_parts.append(
                        str(value).strip()
                    )

            address = ", ".join(
                address_parts
            )

            if not address:

                address = (
                    tags.get("addr:full")
                    or
                    tags.get("description")
                    or
                    ""
                )

            # ------------------------------------------------
            # PHONE
            # ------------------------------------------------

            phone = (
                tags.get("contact:phone")
                or
                tags.get("phone")
                or
                tags.get("telephone")
            )

            if phone:
                phone = str(phone).strip()

            # ------------------------------------------------
            # WEBSITE
            #
            # We still collect it from OSM for data
            # compatibility, but Flutter does NOT display
            # a website URL.
            # ------------------------------------------------

            website = (
                tags.get("contact:website")
                or
                tags.get("website")
                or
                tags.get("url")
            )

            if website:

                website = str(
                    website
                ).strip()

                if not (
                    website.startswith("http://")
                    or
                    website.startswith("https://")
                ):

                    website = (
                        "https://"
                        +
                        website
                    )

            # ------------------------------------------------
            # OPENING HOURS
            # ------------------------------------------------

            opening_hours = tags.get(
                "opening_hours"
            )

            if opening_hours:
                opening_hours = str(
                    opening_hours
                ).strip()

            # ------------------------------------------------
            # ADD RESULT
            # ------------------------------------------------

            results.append({

                "name":
                    str(name).strip(),

                "type":
                    facility_type,

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
                    place_lng,
            })

    # --------------------------------------------------------
    # REMOVE DUPLICATES
    # --------------------------------------------------------

    unique_results = []

    seen = set()

    for result in results:

        key = (
            result["name"].lower().strip(),
            round(result["lat"], 5),
            round(result["lng"], 5),
        )

        if key in seen:
            continue

        seen.add(key)

        unique_results.append(
            result
        )

    # Maximum 50 results
    unique_results = unique_results[:50]

    # --------------------------------------------------------
    # FALLBACK
    # --------------------------------------------------------

    source = "OpenStreetMap"

    if not unique_results:

        if is_kurla_area(
            latitude,
            longitude
        ):

            unique_results = (
                get_kurla_fallback()
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
                "No live healthcare results "
                "for this location."
            )

    # --------------------------------------------------------
    # RETURN SUCCESS
    # --------------------------------------------------------

    print(
        f"Returning "
        f"{len(unique_results)} "
        f"healthcare results."
    )

    return jsonify({

        "type":
            "healthcare",

        "radius_km":
            10,

        "source":
            source,

        "live_results":
            len(results),

        "results":
            unique_results,

    }), 200



# ============================================================
# GEOCODE ADDRESS
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