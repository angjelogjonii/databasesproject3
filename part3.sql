from flask import Flask, request, jsonify, session
from flask_mysqldb import MySQL
from werkzeug.security import generate_password_hash, check_password_hash

app = Flask(__name__)
app.secret_key = 'your_secret_key'

# Database configuration
app.config['MYSQL_HOST'] = 'localhost'
app.config['MYSQL_USER'] = 'your_user'
app.config['MYSQL_PASSWORD'] = 'your_password'
app.config['MYSQL_DB'] = 'welcomehome'

mysql = MySQL(app)

@app.route('/login', methods=['POST'])
def login():
    username = request.json['username']
    password = request.json['password']
    
    cur = mysql.connection.cursor()
    cur.execute("SELECT password FROM people WHERE username = %s", (username,))
    user = cur.fetchone()
    
    if user and check_password_hash(user[0], password):
        session['username'] = username
        return jsonify({'message': 'Login successful'}), 200
    else:
        return jsonify({'message': 'Invalid username or password'}), 401

@app.route('/find_item', methods=['GET'])
def find_item():
    if 'username' not in session:
        return jsonify({'message': 'Unauthorized'}), 401

    item_id = request.args.get('itemID')
    
    cur = mysql.connection.cursor()
    cur.execute("""
        SELECT p.itemID, p.description, p.room_number, p.shelf_number 
        FROM pieces p
        WHERE p.itemID = %s""", (item_id,))
    
    results = cur.fetchall()
    return jsonify(results), 200

@app.route('/find_order_items', methods=['GET'])
def find_order_items():
    if 'username' not in session:
        return jsonify({'message': 'Unauthorized'}), 401

    order_id = request.args.get('orderID')
    
    cur = mysql.connection.cursor()
    cur.execute("""
        SELECT i.itemID, i.category, i.subcategory, p.room_number, p.shelf_number
        FROM items i
        JOIN pieces p ON i.itemID = p.itemID
        JOIN orders_items oi ON i.itemID = oi.itemID
        WHERE oi.orderID = %s""", (order_id,))
    
    results = cur.fetchall()
    return jsonify(results), 200

@app.route('/accept_donation', methods=['POST'])
def accept_donation():
    if 'username' not in session:
        return jsonify({'message': 'Unauthorized'}), 401

    cur = mysql.connection.cursor()
    cur.execute("SELECT role FROM people WHERE username = %s", (session['username'],))
    role = cur.fetchone()
    
    if role[0] != 'staff':
        return jsonify({'message': 'Only staff can accept donations'}), 403

    donor_id = request.json['donorID']
    cur.execute("SELECT * FROM people WHERE username = %s AND role = 'donor'", (donor_id,))
    if not cur.fetchone():
        return jsonify({'message': 'Invalid donor ID'}), 400

    item_data = request.json['items']
    for item in item_data:
        cur.execute("""
            INSERT INTO items (description, category, subcategory, new_or_used, donorID) 
            VALUES (%s, %s, %s, %s, %s)
        """, (item['description'], item['category'], item['subcategory'], item['new_or_used'], donor_id))
        item_id = cur.lastrowid
        
        for piece in item['pieces']:
            cur.execute("""
                INSERT INTO pieces (itemID, pieceNum, room_number, shelf_number) 
                VALUES (%s, %s, %s, %s)
            """, (item_id, piece['pieceNum'], piece['room_number'], piece.get('shelf_number')))

    mysql.connection.commit()
    return jsonify({'message': 'Donation accepted successfully'}), 200

# Additional routes for tasks 5-12 can be implemented similarly

if __name__ == '__main__':
    app.run(debug=True)
