import os
import psycopg2
from flask import Flask, render_template, request, redirect

app = Flask(__name__)


def get_connection():
    return psycopg2.connect(
        host=os.environ["DB_HOST"],
        port=os.environ.get("DB_PORT", "5432"),
        dbname=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
    )


@app.route("/health")
def health():
    return "OK", 200


@app.route("/")
def index():
    conn = get_connection()
    cur = conn.cursor()

    cur.execute("""
        CREATE TABLE IF NOT EXISTS productos (
            id SERIAL PRIMARY KEY,
            nombre VARCHAR(100) NOT NULL,
            precio NUMERIC(10,2) NOT NULL
        )
    """)

    conn.commit()

    cur.execute("""
        SELECT id, nombre, precio
        FROM productos
        ORDER BY id
    """)

    productos = cur.fetchall()

    cur.close()
    conn.close()

    return render_template(
        "index.html",
        productos=productos
    )


@app.route("/agregar", methods=["POST"])
def agregar():
    nombre = request.form["nombre"]
    precio = request.form["precio"]

    conn = get_connection()
    cur = conn.cursor()

    cur.execute(
        """
        INSERT INTO productos (nombre, precio)
        VALUES (%s, %s)
        """,
        (nombre, precio)
    )

    conn.commit()

    cur.close()
    conn.close()

    return redirect("/")


if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=8000
    )