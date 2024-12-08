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

@app.route('/start_order', methods=['POST'])
def start_order():
    # Task 5: Start an Order
    if 'username' not in session:
        return jsonify({'message': 'Unauthorized'}), 401

    cur = mysql.connection.cursor()
    cur.execute("SELECT role FROM people WHERE username = %s", (session['username'],))
    role = cur.fetchone()
    
    if role[0] != 'staff':
        return jsonify({'message': 'Only staff can start orders'}), 403

    client_username = request.json['client_username']
    cur.execute("SELECT * FROM people WHERE username = %s AND role = 'client'", (client_username,))
    if not cur.fetchone():
        return jsonify({'message': 'Invalid client username'}), 400

    cur.execute("INSERT INTO orders (client_username, status) VALUES (%s, %s)", (client_username, 'in progress'))
    order_id = cur.lastrowid
    mysql.connection.commit()
    session['order_id'] = order_id  # Store the order ID in the session
    return jsonify({'message': 'Order started successfully', 'order_id': order_id}), 200

@app.route('/add_to_order', methods=['POST'])
def add_to_order():
    # Task 6: Add to Current Order
    if 'username' not in session:
        return jsonify({'message': 'Unauthorized'}), 401

    order_id = session.get('order_id')
    if not order_id:
        return jsonify({'message': 'No active order'}), 400

    item_id = request.json['item_id']
    cur = mysql.connection.cursor()
    cur.execute("SELECT * FROM items WHERE itemID = %s AND orderID IS NULL", (item_id,))
    if not cur.fetchone():
        return jsonify({'message': 'Item not available for order'}), 400

    cur.execute("UPDATE items SET orderID = %s WHERE itemID = %s", (order_id, item_id))
    mysql.connection.commit()
    return jsonify({'message': 'Item added to order'}), 200

@app.route('/prepare_order', methods=['POST'])
def prepare_order():
    # Task 7: Prepare Order
    if 'username' not in session:
        return jsonify({'message': 'Unauthorized'}), 401

    order_id = request.json['order_id']
    cur = mysql.connection.cursor()
    cur.execute("UPDATE items SET location = 'holding' WHERE orderID = %s", (order_id,))
    mysql.connection.commit()
    return jsonify({'message': 'Order prepared for delivery'}), 200

@app.route('/user_tasks', methods=['GET'])
def user_tasks():
    # Task 8: User's Tasks
    if 'username' not in session:
        return jsonify({'message': 'Unauthorized'}), 401

    cur = mysql.connection.cursor()
    cur.execute("""
        SELECT o.orderID, o.status, o.client_username
        FROM orders o
        JOIN people p ON o.staff_username = p.username OR o.volunteer_username = p.username
        WHERE p.username = %s""", (session['username'],))
    results = cur.fetchall()
    return jsonify(results), 200

@app.route('/rank_system', methods=['GET'])
def rank_system():
    # Task 9: Rank System (Most Popular Category/Subcategory)
    cur = mysql.connection.cursor()
    cur.execute("""
        SELECT category, subcategory, COUNT(*) as order_count
        FROM items
        GROUP BY category, subcategory
        ORDER BY order_count DESC
        LIMIT 1""")
    result = cur.fetchone()
    return jsonify(result), 200

@app.route('/update_order_status', methods=['POST'])
def update_order_status():
    # Task 10: Update Enabled
    if 'username' not in session:
        return jsonify({'message': 'Unauthorized'}), 401

    order_id = request.json['order_id']
    new_status = request.json['new_status']

    cur = mysql.connection.cursor()
    cur.execute("""
        SELECT * FROM orders
        WHERE orderID = %s AND (staff_username = %s OR volunteer_username = %s)""",
        (order_id, session['username'], session['username']))
    if not cur.fetchone():
        return jsonify({'message': 'Not authorized to update this order'}), 403

    cur.execute("UPDATE orders SET status = %s WHERE orderID = %s", (new_status, order_id))
    mysql.connection.commit()
    return jsonify({'message': 'Order status updated successfully'}), 200

@app.route('/year_end_report', methods=['GET'])
def year_end_report():
    # Task 11: Year-End Report
    cur = mysql.connection.cursor()
    cur.execute("""
        SELECT COUNT(DISTINCT client_username) as clients_served, 
               COUNT(*) as total_items_donated, 
               category, COUNT(*) as items_in_category
        FROM items
        GROUP BY category""")
    results = cur.fetchall()
    return jsonify(results), 200

if __name__ == '__main__':
    app.run(debug=True)
