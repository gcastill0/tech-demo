import os
from flask import Flask, jsonify
from flask_cors import CORS
import psycopg2

app = Flask(__name__)
CORS(app)

# Database connection setup using environment variables
def get_db_connection():
    # Fetch the environment variables
    fqdn = os.getenv("FQDN")
    db_name = os.getenv("DB_NAME")
    db_user = os.getenv("DB_USER")
    db_pass = os.getenv("DB_PASS")

    # Ensure all required environment variables are set
    if not fqdn or not db_name or not db_user or not db_pass:
        raise Exception("Database environment variables are not fully set!")

    # Construct the PostgreSQL connection string
    conn_str = f"postgresql://{db_user}:{db_pass}@{fqdn}/{db_name}"
    
    # Establish the database connection
    conn = psycopg2.connect(conn_str)
    return conn

# API endpoint to fetch materials from the database
@app.route('/api/materials', methods=['GET'])
def get_materials():
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute('SELECT filename, bot_name, bot_story FROM robot_records')
    materials = cursor.fetchall()
    cursor.close()
    conn.close()

    # Format the data to be JSON serializable
    material_list = []
    for material in materials:
        material_list.append({
            'filename': material[0],
            'bot_name': material[1],
            'bot_story': material[2]
        })

    return jsonify(material_list)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

