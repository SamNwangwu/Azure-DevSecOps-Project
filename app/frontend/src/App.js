import React, { useState, useEffect } from 'react';
import './App.css';

function App() {
  const [items, setItems] = useState([]);
  const [newItem, setNewItem] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchItems();
  }, []);

  const fetchItems = async () => {
    try {
      setLoading(true);
      const response = await fetch('/api/items');
      if (!response.ok) {
        throw new Error(`HTTP error! Status: ${response.status}`);
      }
      const data = await response.json();
      setItems(data);
      setError(null);
    } catch (error) {
      console.error('Error fetching data:', error);
      setError('Failed to load items. Please try again later.');
    } finally {
      setLoading(false);
    }
  };

  const addItem = async () => {
    if (!newItem.trim()) return;
    
    try {
      setLoading(true);
      const response = await fetch('/api/items', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ name: newItem }),
      });
      
      if (!response.ok) {
        throw new Error(`HTTP error! Status: ${response.status}`);
      }
      
      setNewItem('');
      await fetchItems();
    } catch (error) {
      console.error('Error adding item:', error);
      setError('Failed to add item. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const deleteItem = async (id) => {
    try {
      setLoading(true);
      const response = await fetch(`/api/items/${id}`, {
        method: 'DELETE',
      });
      
      if (!response.ok) {
        throw new Error(`HTTP error! Status: ${response.status}`);
      }
      
      await fetchItems();
    } catch (error) {
      console.error('Error deleting item:', error);
      setError('Failed to delete item. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>DevSecOps Demo App</h1>
        <div className="input-container">
          <input
            type="text"
            value={newItem}
            onChange={(e) => setNewItem(e.target.value)}
            placeholder="Add new item"
            disabled={loading}
          />
          <button 
            onClick={addItem}
            disabled={loading || !newItem.trim()}
          >
            Add
          </button>
        </div>
        {error && <div className="error-message">{error}</div>}
        {loading ? (
          <p>Loading...</p>
        ) : (
          <ul className="items-list">
            {items.length === 0 ? (
              <li className="empty-list">No items yet. Add one above!</li>
            ) : (
              items.map((item) => (
                <li key={item._id || item.id}>
                  <span>{item.name}</span>
                  <button 
                    className="delete-button"
                    onClick={() => deleteItem(item._id || item.id)}
                  >
                    Delete
                  </button>
                </li>
              ))
            )}
          </ul>
        )}
      </header>
    </div>
  );
}

export default App;
