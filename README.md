Login & User Session Handling: Registered users can securely log in with hashed passwords. User sessions ensure only authorized users can access specific features.
Find Single Item: Retrieve locations of all pieces of an item by entering its itemID.
Find Order Items: Fetch details and locations of all items in an order by entering its orderID.
Accept Donations: Staff members can record donations, validate donor IDs, and save item details with locations.
Start an Order: Staff can initiate orders for clients, with the order ID stored in the session.
Add to Current Order: Users can browse available items by category/subcategory and add them to an order.
Prepare Order: Update the location of items to indicate readiness for delivery.
User's Tasks: Display all orders related to the logged-in user, including relevant details.
Rank System: Determine the most popular category/subcategory based on the number of orders.
Update Enabled: Allow authorized users to update the status of orders they are managing.
Year-End Report: Generate a summary of clients served, donations received, and items categorized for reporting purposes.
Handle Duplicate Items: Manage multiple copies of items in the database and ensure features accommodate this functionality.
SQL Injection Prevention: Prepared statements are used for all SQL queries.
XSS Prevention: Ensures backend data integrity, with scope for frontend enhancements.
