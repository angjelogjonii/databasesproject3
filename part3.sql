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
    # Task 1: Login & User Session Handling
    # Retrieve username and password from the request payload
    username = request.json['username']
    password = request.json['password']
    
    # Query the database for the user's hashed password
    cur = mysql.connection.cursor()
    cur.execute("SELECT password FROM people WHERE username = %s", (username,))
    user = cur.fetchone()
    
    # Check if the user exists and verify the password
    if user and check_password_hash(user[0], password):
        session['username'] = username  # Store the username in the session
        return jsonify({'message': 'Login successful'}), 200
    else:
        return jsonify({'message': 'Invalid username or password'}), 401

@app.route('/find_item', methods=['GET'])
def find_item():
    # Task 2: Find Single Item
    # Ensure the user is logged in
    if 'username' not in session:
        return jsonify({'message': 'Unauthorized'}), 401

    # Get the itemID from the query parameters
    item_id = request.args.get('itemID')
    
    # Query the database for the item's pieces and their locations
    cur = mysql.connection.cursor()
    cur.execute("""
        SELECT p.itemID, p.description, p.room_number, p.shelf_number 
        FROM pieces p
        WHERE p.itemID = %s""", (item_id,))
    
    # Fetch all matching records
    results = cur.fetchall()
    return jsonify(results), 200

@app.route('/find_order_items', methods=['GET'])
def find_order_items():
    # Task 3: Find Order Items
    # Ensure the user is logged in
    if 'username' not in session:
        return jsonify({'message': 'Unauthorized'}), 401

    # Get the orderID from the query parameters
    order_id = request.args.get('orderID')
    
    # Query the database to fetch items and their locations for the given order
    cur = mysql.connection.cursor()
    cur.execute("""
        SELECT i.itemID, i.category, i.subcategory, p.room_number, p.shelf_number
        FROM items i
        JOIN pieces p ON i.itemID = p.itemID
        JOIN orders_items oi ON i.itemID = oi.itemID
        WHERE oi.orderID = %s""", (order_id,))
    
    # Fetch all matching records
    results = cur.fetchall()
    return jsonify(results), 200

@app.route('/accept_donation', methods=['POST'])
def accept_donation():
    # Task 4: Accept Donation
    # Ensure the user is logged in
    if 'username' not in session:
        return jsonify({'message': 'Unauthorized'}), 401

    # Verify the logged-in user is a staff member
    cur = mysql.connection.cursor()
    cur.execute("SELECT role FROM people WHERE username = %s", (session['username'],))
    role = cur.fetchone()
    
    if role[0] != 'staff':
        return jsonify({'message': 'Only staff can accept donations'}), 403

    # Get donor ID and verify if the donor exists in the database
    donor_id = request.json['donorID']
    cur.execute("SELECT * FROM people WHERE username = %s AND role = 'donor'", (donor_id,))
    if not cur.fetchone():
        return jsonify({'message': 'Invalid donor ID'}), 400

    # Process the donation items provided in the request
    item_data = request.json['items']
    for item in item_data:
        # Insert the item details into the items table
        cur.execute("""
            INSERT INTO items (description, category, subcategory, new_or_used, donorID) 
            VALUES (%s, %s, %s, %s, %s)
        """, (item['description'], item['category'], item['subcategory'], item['new_or_used'], donor_id))
        item_id = cur.lastrowid  # Get the auto-incremented itemID
        
        # Insert each piece of the item into the pieces table
        for piece in item['pieces']:
            cur.execute("""
                INSERT INTO pieces (itemID, pieceNum, room_number, shelf_number) 
                VALUES (%s, %s, %s, %s)
            """, (item_id, piece['pieceNum'], piece['room_number'], piece.get('shelf_number')))

    # Commit the transaction to save changes
    mysql.connection.commit()
    return jsonify({'message': 'Donation accepted successfully'}), 200

# Additional routes for tasks 5-12 can be implemented similarly

if __name__ == '__main__':
    app.run(debug=True)
